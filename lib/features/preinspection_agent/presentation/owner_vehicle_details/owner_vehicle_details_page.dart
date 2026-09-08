import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/routing/app_back.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/bottom_button.dart';
import '../../../../core/widgets/page_title_bar.dart';
import '../../domain/models/owner_vehicle_details.dart';
import '../../state/claim_flow_provider.dart';

const _indianStates = [
  'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh',
  'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jharkhand',
  'Karnataka', 'Kerala', 'Madhya Pradesh', 'Maharashtra', 'Manipur',
  'Meghalaya', 'Mizoram', 'Nagaland', 'Odisha', 'Punjab',
  'Rajasthan', 'Sikkim', 'Tamil Nadu', 'Telangana', 'Tripura',
  'Uttar Pradesh', 'Uttarakhand', 'West Bengal',
  'Andaman and Nicobar Islands', 'Chandigarh', 'Dadra and Nagar Haveli and Daman and Diu',
  'Delhi', 'Jammu and Kashmir', 'Ladakh', 'Lakshadweep', 'Puducherry',
];

const _products = ['Private Car', 'Two Wheeler', 'Commercial Vehicle', 'Taxi'];
const _makes = [
  'Mahindra', 'Maruti Suzuki', 'Hyundai', 'Tata', 'Honda', 'Toyota', 'Ford',
  'Kia', 'Volkswagen', 'Skoda', 'Renault', 'Nissan', 'MG', 'Jeep',
];
const _models = ['Scorpio-N', 'XUV 700', 'Thar', 'Bolero', 'XUV 300'];
const _variants = ['Z2', 'Z4', 'Z6', 'Z8', 'Z8L'];
const _ownerSerialNumbers = ['1', '2', '3', '4', '5'];
const _surveyTypes = ['pre inspection', 'Valuation'];

/// Port of `OwnerVehicleDetailsPage.jsx`.
class OwnerVehicleDetailsPage extends ConsumerStatefulWidget {
  const OwnerVehicleDetailsPage({super.key});

  @override
  ConsumerState<OwnerVehicleDetailsPage> createState() => _OwnerVehicleDetailsPageState();
}

class _OwnerVehicleDetailsPageState extends ConsumerState<OwnerVehicleDetailsPage> {
  final _ownerNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _odometerController = TextEditingController();
  final _regNoController = TextEditingController();
  final _idvController = TextEditingController();

  String _surveyType = _surveyTypes.first;
  String? _ownerSerialNumber;
  String? _state;
  DateTime? _registrationDate;
  String? _product;
  String? _make;
  String? _model;
  String? _variant;
  DateTime? _manufacturingYear;

  final Map<String, String?> _errors = {};

  @override
  void dispose() {
    _ownerNameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _odometerController.dispose();
    _regNoController.dispose();
    _idvController.dispose();
    super.dispose();
  }

  Future<void> _pickRegistrationDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _registrationDate ?? DateTime.now(),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _registrationDate = picked;
        _errors['registrationDate'] = null;
      });
    }
  }

  Future<void> _pickManufacturingYear() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _manufacturingYear ?? DateTime.now(),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null) {
      setState(() {
        _manufacturingYear = picked;
        _errors['manufacturingYear'] = null;
      });
    }
  }

  bool _validate() {
    final errors = <String, String?>{
      'ownerName': _ownerNameController.text.trim().isEmpty ? 'Owner name is required' : null,
      'mobile': !RegExp(r'^\d{10}$').hasMatch(_mobileController.text.trim()) ? 'Enter a valid 10-digit mobile' : null,
      'email': !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(_emailController.text.trim()) ? 'Enter a valid email' : null,
      'odometer': _odometerController.text.trim().isEmpty ? 'Odometer reading is required' : null,
      'registrationNumber': _regNoController.text.trim().isEmpty ? 'Registration number is required' : null,
      'state': _state == null ? 'Select a state' : null,
      'registrationDate': _registrationDate == null ? 'Select registration date' : null,
      'product': _product == null ? 'Select a product' : null,
      'make': _make == null ? 'Select a make' : null,
      'model': _model == null ? 'Select a model' : null,
      'variant': _variant == null ? 'Select a variant' : null,
      'manufacturingYear': _manufacturingYear == null ? 'Select manufacturing year' : null,
      'ownerSerialNumber': _ownerSerialNumber == null ? 'Select owner serial number' : null,
      'idv': _idvController.text.trim().isEmpty ? 'Present market value is required' : null,
    }..removeWhere((key, value) => value == null);

    setState(() {
      _errors
        ..clear()
        ..addAll(errors);
    });
    return errors.isEmpty;
  }

  void _submit() {
    if (!_validate()) return;

    final details = OwnerVehicleDetails(
      surveyType: _surveyType,
      ownerName: _ownerNameController.text.trim(),
      mobile: _mobileController.text.trim(),
      email: _emailController.text.trim(),
      odometer: _odometerController.text.trim(),
      registrationNumber: _regNoController.text.trim().toUpperCase(),
      state: _state!,
      registrationDate: DateFormat('dd-MM-yyyy').format(_registrationDate!),
      product: _product!,
      make: _make!,
      model: _model!,
      variant: _variant!,
      manufacturingYear: DateFormat('MM-yyyy').format(_manufacturingYear!),
      ownerSerialNumber: _ownerSerialNumber!,
      idv: _idvController.text.trim(),
    );

    ref.read(claimFlowProvider.notifier).setOwnerVehicleDetails(details);
    context.go(AppRoutes.documentUpload);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const AppHeader(),
          PageTitleBar(
            title: 'Owner & Vehicle Details',
            onBack: () => appBack(context, AppRoutes.claimStart),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SurveyTypeField(
                    value: _surveyType,
                    onChanged: (v) => setState(() => _surveyType = v),
                  ),
                  _Field(
                    label: 'Owner Name',
                    placeholder: 'Naman Singh',
                    controller: _ownerNameController,
                    error: _errors['ownerName'],
                    inputFormatterAllowed: Validators.isLettersOnly,
                  ),
                  _Field(
                    label: 'Mobile Number',
                    placeholder: '9910476839',
                    controller: _mobileController,
                    error: _errors['mobile'],
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    prefixText: '+91',
                    inputFormatterAllowed: Validators.isDigitsOnly,
                  ),
                  _Field(
                    label: 'Email ID',
                    placeholder: 'UserName@gmail.com',
                    controller: _emailController,
                    error: _errors['email'],
                    keyboardType: TextInputType.emailAddress,
                  ),
                  _Field(
                    label: 'Odometer Reading ( KM )',
                    placeholder: '9000',
                    controller: _odometerController,
                    error: _errors['odometer'],
                    keyboardType: TextInputType.number,
                    inputFormatterAllowed: Validators.isDigitsOnly,
                  ),
                  _Field(
                    label: 'Registration Number',
                    placeholder: 'MH 49 DS 2345',
                    controller: _regNoController,
                    error: _errors['registrationNumber'],
                    inputFormatterAllowed: Validators.isPlateChar,
                    textCapitalization: TextCapitalization.characters,
                  ),
                  _DropdownField(
                    label: 'Select State',
                    placeholder: 'Maharashtra',
                    value: _state,
                    items: _indianStates,
                    error: _errors['state'],
                    onChanged: (v) => setState(() {
                      _state = v;
                      _errors['state'] = null;
                    }),
                  ),
                  _DateField(
                    label: 'Registration Date',
                    value: _registrationDate,
                    error: _errors['registrationDate'],
                    format: 'dd-MM-yyyy',
                    onTap: _pickRegistrationDate,
                  ),
                  _DropdownField(
                    label: 'Select Product',
                    placeholder: 'Private Car',
                    value: _product,
                    items: _products,
                    error: _errors['product'],
                    onChanged: (v) => setState(() {
                      _product = v;
                      _errors['product'] = null;
                    }),
                  ),
                  _DropdownField(
                    label: 'Select Make',
                    placeholder: 'Mahindra',
                    value: _make,
                    items: _makes,
                    error: _errors['make'],
                    onChanged: (v) => setState(() {
                      _make = v;
                      _errors['make'] = null;
                    }),
                  ),
                  _DropdownField(
                    label: 'Select Model',
                    placeholder: 'Scorpio-N',
                    value: _model,
                    items: _models,
                    error: _errors['model'],
                    onChanged: (v) => setState(() {
                      _model = v;
                      _errors['model'] = null;
                    }),
                  ),
                  _DropdownField(
                    label: 'Select Variant',
                    placeholder: 'Z2',
                    value: _variant,
                    items: _variants,
                    error: _errors['variant'],
                    onChanged: (v) => setState(() {
                      _variant = v;
                      _errors['variant'] = null;
                    }),
                  ),
                  _DateField(
                    label: 'Select Manufacturing Year',
                    value: _manufacturingYear,
                    error: _errors['manufacturingYear'],
                    format: 'MM-yyyy',
                    onTap: _pickManufacturingYear,
                  ),
                  _DropdownField(
                    label: 'Owner Serial Number',
                    placeholder: '2',
                    value: _ownerSerialNumber,
                    items: _ownerSerialNumbers,
                    error: _errors['ownerSerialNumber'],
                    onChanged: (v) => setState(() {
                      _ownerSerialNumber = v;
                      _errors['ownerSerialNumber'] = null;
                    }),
                  ),
                  _Field(
                    label: 'Present Market Value (Estimated)/ IDV',
                    placeholder: '99,999',
                    controller: _idvController,
                    error: _errors['idv'],
                    keyboardType: TextInputType.number,
                    prefixText: '\u20B9',
                    inputFormatterAllowed: Validators.isDigitsOnly,
                  ),
                  const SizedBox(height: 8),
                  BottomButton(label: 'Next', onPressed: _submit),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.placeholder,
    required this.controller,
    this.error,
    this.keyboardType,
    this.maxLength,
    this.prefixText,
    this.inputFormatterAllowed,
    this.textCapitalization = TextCapitalization.none,
  });

  final String label;
  final String placeholder;
  final TextEditingController controller;
  final String? error;
  final TextInputType? keyboardType;
  final int? maxLength;
  final String? prefixText;
  final bool Function(String)? inputFormatterAllowed;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
          const SizedBox(height: 5),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLength: maxLength,
            textCapitalization: textCapitalization,
            inputFormatters: inputFormatterAllowed == null
                ? null
                : [
                    TextInputFormatter.withFunction((oldValue, newValue) {
                      if (newValue.text.isEmpty || inputFormatterAllowed!(newValue.text)) {
                        return newValue;
                      }
                      return oldValue;
                    }),
                  ],
            decoration: InputDecoration(
              hintText: placeholder,
              // A plain `prefixText` stays hidden until the field is focused,
              // so an empty Mobile Number box showed no "+91" at all. A prefix
              // widget renders unconditionally.
              prefixIcon: prefixText == null
                  ? null
                  : Padding(
                      padding: const EdgeInsets.only(left: 16, right: 8),
                      child: Text(
                        prefixText!,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
              prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
              counterText: '',
              filled: true,
              fillColor: AppColors.bgInput,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: error != null ? AppColors.statusPending : AppColors.borderInput),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: error != null ? AppColors.statusPending : AppColors.borderInput),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(error!, style: const TextStyle(color: AppColors.statusPending, fontSize: 14)),
            ),
        ],
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.placeholder,
    required this.value,
    required this.items,
    required this.onChanged,
    this.error,
  });

  final String label;
  final String placeholder;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
          const SizedBox(height: 5),
          DropdownButtonFormField<String>(
            initialValue: value,
            isExpanded: true,
            hint: Text(placeholder, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: onChanged,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.bgInput,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: error != null ? AppColors.statusPending : AppColors.borderInput),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            ),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(error!, style: const TextStyle(color: AppColors.statusPending, fontSize: 14)),
            ),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
    required this.format,
    this.error,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final String format;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final text = value == null ? '' : DateFormat(format).format(value!);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
          const SizedBox(height: 5),
          InkWell(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.bgInput,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: error != null ? AppColors.statusPending : AppColors.borderInput),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(text.isEmpty ? '' : text,
                      style: TextStyle(fontSize: 14, color: text.isEmpty ? AppColors.textSecondary : AppColors.textPrimary)),
                  const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
          if (text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Selected: $text', style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            ),
          if (error != null && text.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(error!, style: const TextStyle(color: AppColors.statusPending, fontSize: 14)),
            ),
        ],
      ),
    );
  }
}


/// Survey-type radio group -- preinspection-only. Lets the agent mark whether
/// this is a "pre inspection" or a "Valuation" survey.
class _SurveyTypeField extends StatelessWidget {
  const _SurveyTypeField({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Survey type',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final option in _surveyTypes) ...[
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(option),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            width: 2,
                            color: option == value
                                ? AppColors.btnPrimary
                                : AppColors.textSecondary,
                          ),
                        ),
                        child: option == value
                            ? Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.btnPrimary,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        option,
                        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 32),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
