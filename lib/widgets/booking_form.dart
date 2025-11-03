import 'dart:async';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:oktoast/oktoast.dart';
import 'package:provider/provider.dart';
import 'package:xfin/database/app_database.dart';
import 'package:xfin/l10n/app_localizations.dart';

class BookingForm extends StatefulWidget {
  final Booking? booking;

  const BookingForm({super.key, this.booking});

  @override
  State<BookingForm> createState() => _BookingFormState();
}

class _BookingFormState extends State<BookingForm> {
  final _formKey = GlobalKey<FormState>();

  late DateTime _date;
  late TextEditingController _amountController;
  late TextEditingController _reasonController;
  late TextEditingController _notesController;
  late int? _accountId;
  late bool _excludeFromAverage;
  late bool _isGenerated;

  late List<String> _distinctReasons;
  StreamSubscription<List<String>>? _reasonSubscription;

  final _disallowedReasons = ['überweisung'];

  @override
  void initState() {
    super.initState();
    final booking = widget.booking;
    final db = Provider.of<AppDatabase>(context, listen: false);

    _distinctReasons = [];
    _reasonSubscription = db.bookingsDao.watchDistinctReasons().listen((reasons) {
      setState(() {
        _distinctReasons = reasons;
      });
    });

    if (booking != null) {
      // -> edit existing booking
      final dateString = booking.date.toString();
      _date = DateTime.parse(
          '${dateString.substring(0, 4)}-${dateString.substring(4, 6)}-${dateString.substring(6, 8)}');
      _amountController = 
          TextEditingController(text: booking.amount.toString());
      _reasonController = TextEditingController(text: booking.reason);
      _notesController = TextEditingController(text: booking.notes);
      _excludeFromAverage = booking.excludeFromAverage;
      _isGenerated = booking.isGenerated;
      _accountId = booking.accountId;
    } else {
      // -> create new booking
      _date = DateTime.now();
      _amountController = TextEditingController();
      _reasonController = TextEditingController();
      _notesController = TextEditingController();
      _accountId = null;
      _excludeFromAverage = false;
      _isGenerated = false;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    _notesController.dispose();
    _reasonSubscription?.cancel();
    super.dispose();
  }

  Future<void> _performMerge(AppDatabase db, Booking existingBooking,
      BookingsCompanion newBooking) async {
    final mergedAmount = existingBooking.amount + newBooking.amount.value;
    final updatedCompanion = existingBooking
        .toCompanion(false)
        .copyWith(amount: drift.Value(mergedAmount));
    await db.bookingsDao
        .updateBookingAndUpdateAccount(existingBooking, updatedCompanion);
  }

  Future<void> _saveForm() async {
    final l10n = AppLocalizations.of(context)!;
    if (_formKey.currentState!.validate()) {
      final db = Provider.of<AppDatabase>(context, listen: false);
      final amount = double.parse(_amountController.text.replaceAll(',', '.'));

      if (widget.booking == null) {
        // Only for new bookings
        if (_accountId != null && amount < 0) {
          final receivingAccount = await db.accountsDao.getAccount(_accountId!);
          if (receivingAccount.balance + amount < 0) {
            showToast(l10n.insufficientBalance);
            return;
          }
        }
      }

      final dateAsInt = int.parse(DateFormat('yyyyMMdd').format(_date));
      final companion = BookingsCompanion(
        date: drift.Value(dateAsInt),
        reason: drift.Value(_reasonController.text.trim()),
        notes: drift.Value(
            _notesController.text.isEmpty ? null : _notesController.text),
        excludeFromAverage: drift.Value(_excludeFromAverage),
        isGenerated: drift.Value(_isGenerated),
        amount: drift.Value(amount),
        accountId: drift.Value(_accountId!),
      );

      if (widget.booking == null && _notesController.text.isEmpty) {
        final mergeable = await db.bookingsDao.findMergeableBooking(companion);

        if (mergeable != null && mounted) {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(l10n.mergeBookings),
              content: Text(l10n.mergeBookingsQuestion),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(l10n.createNew),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(l10n.merge),
                ),
              ],
            ),
          );

          if (confirmed == true) {
            await _performMerge(db, mergeable, companion);
          } else {
            await db.bookingsDao.createBookingAndUpdateAccount(companion);
          }
        } else {
          await db.bookingsDao.createBookingAndUpdateAccount(companion);
        }
      } else if (widget.booking == null) {
        await db.bookingsDao.createBookingAndUpdateAccount(companion);
      } else {
        await db.bookingsDao.updateBookingAndUpdateAccount(
          widget.booking!,
          companion.copyWith(id: drift.Value(widget.booking!.id)),
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  String? _validateDate(DateTime? value, AppLocalizations l10n) {
    if (value != null && value.isAfter(DateTime.now())) {
      return l10n.dateCannotBeInTheFuture;
    }
    return null;
  }

  String? _validateAmount(String? value, AppLocalizations l10n) {
    if (value == null || value.isEmpty) {
      return l10n.pleaseEnterAnAmount;
    }
    final cleanValue = value.replaceAll(',', '.');
    final amount = double.tryParse(cleanValue);
    if (amount == null) {
      return l10n.invalidInput;
    }
    if (RegExp(r'^-?\d+(\.\d{3,})$').hasMatch(cleanValue)) {
      return l10n.tooManyDecimalPlaces;
    }
    return null;
  }

  String? _validateReason(String? value, AppLocalizations l10n) {
    if (value == null || value.isEmpty) {
      return l10n.pleaseEnterAReason;
    }
    if (_disallowedReasons.contains(value.trim().toLowerCase())) {
      return l10n.reasonReservedForTransfer;
    }
    return null;
  }

  String? _validateAccount(int? value, AppLocalizations l10n) {
    if (value == null) {
      return l10n.pleaseSelectAnAccount;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<AppDatabase>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        key: const Key('date_field'),
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: l10n.date,
                          border: const OutlineInputBorder(),
                          errorMaxLines: 2,
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.calendar_today),
                            onPressed: () async {
                              final pickedDate = await showDatePicker(
                                context: context,
                                initialDate: _date,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2101),
                              );
                              if (pickedDate != null && pickedDate != _date) {
                                setState(() {
                                  _date = pickedDate;
                                });
                              }
                            },
                          ),
                        ),
                        controller: TextEditingController(
                          text: DateFormat('dd.MM.yyyy').format(_date),
                        ),
                        validator: (_) => _validateDate(_date, l10n),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        key: const Key('amount_field'),
                        controller: _amountController,
                        decoration: InputDecoration(
                          labelText: l10n.amount,
                          border: const OutlineInputBorder(),
                          suffixText: '€',
                          errorMaxLines: 2,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            signed: true, decimal: true),
                        validator: (value) => _validateAmount(value, l10n),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Autocomplete<String>(
                  key: const Key('reason_field'),
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return const Iterable<String>.empty();
                    }
                    return _distinctReasons.where((reason) {
                      return reason.toLowerCase().contains(textEditingValue.text.toLowerCase());
                    });
                  },
                  onSelected: (String selection) {
                    setState(() {
                      _reasonController.text = selection;
                    });
                  },
                  fieldViewBuilder: (BuildContext context,
                      TextEditingController textEditingController,
                      FocusNode focusNode,
                      void Function() onFieldSubmitted) {
                    // For existing bookings, ensure the Autocomplete's internal controller
                    // reflects the initial reason from _reasonController.
                    if (widget.booking != null &&
                        _reasonController.text.isNotEmpty &&
                        textEditingController.text != _reasonController.text) {
                      textEditingController.text = _reasonController.text;
                    }
                    return TextFormField(
                      controller: textEditingController,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        labelText: l10n.reason,
                        border: const OutlineInputBorder(),
                        errorMaxLines: 2,
                      ),
                      validator: (value) => _validateReason(value, l10n),
                      onChanged: (value) {
                        _reasonController.text = value; // Keep _reasonController in sync
                      },
                      onFieldSubmitted: (String value) {
                        onFieldSubmitted();
                        _reasonController.text = value; // Also update on submit
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
                StreamBuilder<List<Account>>(
                  stream: db.accountsDao.watchCashAccounts(),
                  builder: (context, snapshot) {
                    final accounts = snapshot.data ?? [];
                    return DropdownButtonFormField<int>(
                      key: const Key('account_dropdown'),
                      initialValue: _accountId,
                      decoration: InputDecoration(
                        labelText: l10n.account,
                        border: const OutlineInputBorder(),
                        errorMaxLines: 2,
                      ),
                      items: accounts.map((account) {
                        return DropdownMenuItem(
                            value: account.id, child: Text(account.name));
                      }).toList(),
                      onChanged: (value) => setState(() => _accountId = value),
                      validator: (value) => _validateAccount(value, l10n),
                    );
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('notes_field'),
                  controller: _notesController,
                  decoration: InputDecoration(
                      labelText: l10n.notes,
                      border: const OutlineInputBorder()),
                ),
                CheckboxListTile(
                  key: const Key('exclude_checkbox'),
                  title: Text(l10n.excludeFromAverage),
                  value: _excludeFromAverage,
                  onChanged: (value) =>
                      setState(() => _excludeFromAverage = value ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(l10n.cancel)),
                    const SizedBox(width: 8),
                    ElevatedButton(
                        onPressed: _saveForm, child: Text(l10n.save)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
