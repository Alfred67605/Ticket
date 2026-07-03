import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/utils/date_utils.dart';
import '../../data/repositories/event_repository.dart';
import '../../data/models/event_model.dart';
import '../common/widgets/app_button.dart';
import '../common/widgets/app_text_field.dart';

class CreateEventScreen extends StatefulWidget {
  final EventModel? eventModel; // null = crear, model = editar

  const CreateEventScreen({super.key, this.eventModel});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _organizerCtrl = TextEditingController();
  final _capacityCtrl = TextEditingController();

  DateTime? _eventDate;
  DateTime? _presaleStart;
  DateTime? _presaleEnd;
  final _presalePriceCtrl = TextEditingController();

  String _selectedCategory = 'General';
  String _selectedStatus = 'active';
  String _selectedMediaPreference = 'both';
  File? _imageFile;
  File? _videoFile;
  bool _isLoading = false;
  bool _isEditMode = false;

  List<Map<String, dynamic>> _ticketTypes = [
    {'name': 'General', 'price': '', 'stock': ''},
  ];

  final List<String> _categories = [
    'General', 'Conciertos', 'Deportes', 'Teatro', 'Festivales',
    'Cultura', 'Gastronomía', 'Educación',
  ];

  final List<String> _organizers = [
    'Gobernación de Potosí',
    'Alcaldía de Potosí',
    'Universidad Autónoma Tomás Frías',
    'Ministerio de Culturas',
    'Empresa Privada',
    'Organización Independiente',
  ];

  final List<String> _locations = [
    'Teatro IV Centenario',
    'Teatro Municipal de Potosí',
    'Coliseo Ciudad de Potosí',
    'Estadio Víctor Agustín Ugarte',
    'Plaza Principal 10 de Noviembre',
    'Centro Cultural IV Centenario',
    'Casa Nacional de Moneda',
    'Otro (Escribir ubicación)',
  ];

  String _selectedLocation = 'Teatro IV Centenario';
  bool _showCustomLocationField = false;

  @override
  void initState() {
    super.initState();
    if (widget.eventModel != null) {
      _isEditMode = true;
      final m = widget.eventModel!;
      _titleCtrl.text = m.event.title;
      _descCtrl.text = m.event.description;
      _locationCtrl.text = m.event.location;
      _organizerCtrl.text = m.event.organizer;
      _capacityCtrl.text = '${m.event.capacity}';
      _selectedCategory = m.event.category;
      _selectedStatus = m.event.status;
      _selectedMediaPreference = m.event.mediaPreference;
      _eventDate = m.event.eventDate;

      if (_locations.contains(m.event.location)) {
        _selectedLocation = m.event.location;
        _showCustomLocationField = false;
      } else {
        _selectedLocation = 'Otro (Escribir ubicación)';
        _showCustomLocationField = true;
      }

      if (m.ticketTypes.isNotEmpty) {
        _ticketTypes = m.ticketTypes.map<Map<String, dynamic>>((t) => {
          'id': t.id,
          'name': t.name,
          'price': '${t.price}',
          'stock': '${t.stock}',
        }).toList();
      }

      if (m.presale != null) {
        final ps = m.presale!;
        _presalePriceCtrl.text = '${ps.presalePrice}';
        _presaleStart = ps.startDate;
        _presaleEnd = ps.endDate;
      }
    } else {
      _organizerCtrl.text = 'Gobernación de Potosí';
      _locationCtrl.text = 'Teatro IV Centenario';
      _selectedLocation = 'Teatro IV Centenario';
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _organizerCtrl.dispose();
    _capacityCtrl.dispose();
    _presalePriceCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) setState(() => _imageFile = File(picked.path));
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final picked = await picker.pickVideo(source: ImageSource.gallery);
    if (picked != null) setState(() => _videoFile = File(picked.path));
  }

  Future<void> _pickDate(BuildContext context, {required bool isEventDate}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      if (!mounted) return;
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (!mounted) return;
      final dt = DateTime(
        picked.year,
        picked.month,
        picked.day,
        time?.hour ?? 20,
        time?.minute ?? 0,
      );
      setState(() {
        if (isEventDate) {
          _eventDate = dt;
        } else if (_presaleStart == null) {
          _presaleStart = dt;
        } else {
          _presaleEnd = dt;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_eventDate == null) {
      _showMessage('Selecciona la fecha del evento', isError: true);
      return;
    }
    if (_ticketTypes.isEmpty) {
      _showMessage('Agrega al menos un tipo de entrada', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final List<Map<String, dynamic>> parsedTicketTypes = _ticketTypes.map((t) => {
        if (t['id'] != null) 'id': t['id'],
        'name': t['name'] as String,
        'price': double.parse(t['price'].toString()),
        'stock': int.parse(t['stock'].toString()),
      }).toList();

      final eventRepo = Provider.of<EventRepository>(context, listen: false);

      final presalePrice = _presalePriceCtrl.text.isNotEmpty ? double.tryParse(_presalePriceCtrl.text) : null;

      if (_isEditMode) {
        await eventRepo.updateEvent(
          widget.eventModel!.id,
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          location: _locationCtrl.text.trim(),
          organizer: _organizerCtrl.text.trim(),
          category: _selectedCategory,
          status: _selectedStatus,
          mediaPreference: _selectedMediaPreference,
          eventDate: _eventDate,
          capacity: int.parse(_capacityCtrl.text.trim()),
          ticketTypesList: parsedTicketTypes,
          imagePath: _imageFile?.path,
          videoPath: _videoFile?.path,
          presalePrice: presalePrice,
          presaleStart: _presaleStart,
          presaleEnd: _presaleEnd,
        );
      } else {
        await eventRepo.createEvent(
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          location: _locationCtrl.text.trim(),
          organizer: _organizerCtrl.text.trim(),
          category: _selectedCategory,
          eventDate: _eventDate!,
          capacity: int.parse(_capacityCtrl.text.trim()),
          ticketTypesList: parsedTicketTypes,
          imagePath: _imageFile?.path,
          videoPath: _videoFile?.path,
          presalePrice: presalePrice,
          presaleStart: _presaleStart,
          presaleEnd: _presaleEnd,
        );
      }

      if (mounted) {
        _showMessage(_isEditMode ? 'Evento actualizado correctamente' : 'Evento creado correctamente');
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showMessage('Error al guardar el evento: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bg : AppColors.bgLight,
      appBar: AppBar(
        title: Text(_isEditMode ? 'Editar Evento' : 'Nuevo Evento'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white : AppColors.textPrimaryLight),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTextField(
                controller: _titleCtrl,
                label: 'Título del evento',
                hint: 'Concierto de Gala',
                validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),

              AppTextField(
                controller: _descCtrl,
                label: 'Descripción',
                hint: 'Escribe detalles sobre el evento...',
                maxLines: 3,
                validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),

              // Ubicación dropdown
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Ubicación / Lugar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    value: _locations.contains(_selectedLocation) ? _selectedLocation : 'Otro (Escribir ubicación)',
                    dropdownColor: isDark ? AppColors.surface : Colors.white,
                    decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                    items: _locations.map((loc) => DropdownMenuItem(value: loc, child: Text(loc, style: const TextStyle(fontSize: 14)))).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedLocation = val;
                          _showCustomLocationField = (val == 'Otro (Escribir ubicación)');
                          if (!_showCustomLocationField) {
                            _locationCtrl.text = val;
                          } else {
                            _locationCtrl.clear();
                          }
                        });
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (_showCustomLocationField) ...[
                AppTextField(
                  controller: _locationCtrl,
                  label: 'Escribe la ubicación personalizada',
                  hint: 'Calle Chayanta #45',
                  validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),
              ],

              // Organizador dropdown
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Organizador', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    value: _organizers.contains(_organizerCtrl.text) ? _organizerCtrl.text : _organizers.first,
                    dropdownColor: isDark ? AppColors.surface : Colors.white,
                    decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                    items: _organizers.map((org) => DropdownMenuItem(value: org, child: Text(org, style: const TextStyle(fontSize: 14)))).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _organizerCtrl.text = val);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _capacityCtrl,
                      label: 'Capacidad Total',
                      hint: '500',
                      keyboardType: TextInputType.number,
                      validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Categoría', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          dropdownColor: isDark ? AppColors.surface : Colors.white,
                          decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                          items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 14)))).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedCategory = val);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Estado', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        DropdownButtonFormField<String>(
                          value: _selectedStatus,
                          dropdownColor: isDark ? AppColors.surface : Colors.white,
                          decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                          items: const [
                            DropdownMenuItem(value: 'active', child: Text('🟢 Activo', style: TextStyle(fontSize: 14))),
                            DropdownMenuItem(value: 'inactive', child: Text('🟡 Inactivo', style: TextStyle(fontSize: 14))),
                            DropdownMenuItem(value: 'cancelled', child: Text('🔴 Cancelado', style: TextStyle(fontSize: 14))),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedStatus = val);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Preferencia de Medios', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        DropdownButtonFormField<String>(
                          value: _selectedMediaPreference,
                          dropdownColor: isDark ? AppColors.surface : Colors.white,
                          decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                          items: const [
                            DropdownMenuItem(value: 'both', child: Text('🎬 Todo', style: TextStyle(fontSize: 14))),
                            DropdownMenuItem(value: 'image', child: Text('🖼️ Solo Imagen', style: TextStyle(fontSize: 14))),
                            DropdownMenuItem(value: 'video', child: Text('📹 Solo Video', style: TextStyle(fontSize: 14))),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedMediaPreference = val);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Date Selector
              Card(
                child: ListTile(
                  leading: const Icon(Icons.calendar_today_rounded, color: AppColors.primary),
                  title: const Text('Fecha y Hora del Evento'),
                  subtitle: Text(_eventDate == null ? 'No seleccionada' : AppDateUtils.formatFull(_eventDate!.toIso8601String())),
                  trailing: const Icon(Icons.edit_calendar_rounded),
                  onTap: () => _pickDate(context, isEventDate: true),
                ),
              ),
              const SizedBox(height: 16),

              // Pick Media (Image and Video)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.image_rounded),
                      label: Text(_imageFile == null ? 'Subir Imagen' : 'Cambiar Imagen'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickVideo,
                      icon: const Icon(Icons.video_library_rounded),
                      label: Text(_videoFile == null ? 'Subir Video' : 'Cambiar Video'),
                    ),
                  ),
                ],
              ),
              if (_imageFile != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text('Imagen: ${_imageFile!.path.split("/").last}')),
              if (_videoFile != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text('Video: ${_videoFile!.path.split("/").last}')),
              const SizedBox(height: 24),

              // Ticket Types Dynamic Fields
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tipos de Entrada', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _ticketTypes.add({'name': '', 'price': '', 'stock': ''});
                      });
                    },
                    icon: const Icon(Icons.add_circle_rounded, color: AppColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _ticketTypes.length,
                itemBuilder: (ctx, i) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextField(
                              controller: TextEditingController(text: _ticketTypes[i]['name'])..selection = TextSelection.collapsed(offset: _ticketTypes[i]['name'].toString().length),
                              decoration: const InputDecoration(labelText: 'Nombre', contentPadding: EdgeInsets.symmetric(horizontal: 8)),
                              onChanged: (val) => _ticketTypes[i]['name'] = val,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: TextEditingController(text: _ticketTypes[i]['price'])..selection = TextSelection.collapsed(offset: _ticketTypes[i]['price'].toString().length),
                              decoration: const InputDecoration(labelText: 'Precio', contentPadding: EdgeInsets.symmetric(horizontal: 8)),
                              keyboardType: TextInputType.number,
                              onChanged: (val) => _ticketTypes[i]['price'] = val,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: TextEditingController(text: _ticketTypes[i]['stock'])..selection = TextSelection.collapsed(offset: _ticketTypes[i]['stock'].toString().length),
                              decoration: const InputDecoration(labelText: 'Stock', contentPadding: EdgeInsets.symmetric(horizontal: 8)),
                              keyboardType: TextInputType.number,
                              onChanged: (val) => _ticketTypes[i]['stock'] = val,
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _ticketTypes.removeAt(i);
                              });
                            },
                            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Preventa inputs
              const Text('Configurar Preventa (Opcional)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              AppTextField(
                controller: _presalePriceCtrl,
                label: 'Precio Especial',
                hint: '25.0',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Card(
                      child: ListTile(
                        title: const Text('Inicio Preventa', style: TextStyle(fontSize: 12)),
                        subtitle: Text(_presaleStart == null ? '—' : AppDateUtils.formatDate(_presaleStart!.toIso8601String())),
                        onTap: () => _pickDate(context, isEventDate: false),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Card(
                      child: ListTile(
                        title: const Text('Fin Preventa', style: TextStyle(fontSize: 12)),
                        subtitle: Text(_presaleEnd == null ? '—' : AppDateUtils.formatDate(_presaleEnd!.toIso8601String())),
                        onTap: () => _pickDate(context, isEventDate: false),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              AppButton(
                text: _isEditMode ? 'Guardar Evento' : 'Crear Evento',
                isLoading: _isLoading,
                onPressed: _submit,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
