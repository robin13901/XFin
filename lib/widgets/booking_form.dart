import 'dart:async';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:oktoast/oktoast.dart';
import 'package:provider/provider.dart';
import 'package:xfin/database/app_database.dart';
import 'package:xfin/l10n/app_localizations.dart';

import '../providers/base_currency_provider.dart';
import '../validators.dart';

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
  late TextEditingController _categoryController;
  late TextEditingController _notesController;
  late int? _accountId;
  late bool _excludeFromAverage;
  late bool _isGenerated;

  late List<String> _distinctCategories;
  StreamSubscription<List<String>>? _categorySubscription;

  @override
  void initState() {
    super.initState();
    final booking = widget.booking;
    final db = Provider.of<AppDatabase>(context, listen: false);

    _distinctCategories = [];
    _categorySubscription =
        db.bookingsDao.watchDistinctCategories().listen((categories) {
      setState(() {
        _distinctCategories = categories;
      });
    });

    if (booking != null) {
      // -> edit existing booking
      final dateString = booking.date.toString();
      _date = DateTime.parse(
          '${dateString.substring(0, 4)}-${dateString.substring(4, 6)}-${dateString.substring(6, 8)}');
      _amountController =
          TextEditingController(text: booking.amount.toString());
      _categoryController = TextEditingController(text: booking.category);
      _notesController = TextEditingController(text: booking.notes);
      _excludeFromAverage = booking.excludeFromAverage;
      _isGenerated = booking.isGenerated;
      _accountId = booking.accountId;
    } else {
      // -> create new booking
      _date = DateTime.now();
      _amountController = TextEditingController();
      _categoryController = TextEditingController();
      _notesController = TextEditingController();
      _accountId = null;
      _excludeFromAverage = false;
      _isGenerated = false;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _categoryController.dispose();
    _notesController.dispose();
    _categorySubscription?.cancel();
    super.dispose();
  }

  Future<void> _performMerge(AppDatabase db, Booking existingBooking,
      BookingsCompanion newBooking) async {
    final mergedAmount = existingBooking.amount + newBooking.amount.value;
    final updatedCompanion = existingBooking
        .toCompanion(false)
        .copyWith(amount: drift.Value(mergedAmount));

    if (await db.accountsDao.leadsToInconsistentBalanceHistory(
      originalBooking: existingBooking,
      newBooking: updatedCompanion,
    )) {
      if (mounted) {
        showToast(AppLocalizations.of(context)!
            .actionCancelledDueToDataInconsistency);
      }
      return;
    }

    await db.bookingsDao.updateBooking(existingBooking, updatedCompanion);
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
        category: drift.Value(_categoryController.text.trim()),
        notes: drift.Value(
            _notesController.text.isEmpty ? null : _notesController.text),
        excludeFromAverage: drift.Value(_excludeFromAverage),
        isGenerated: drift.Value(_isGenerated),
        amount: drift.Value(amount),
        accountId: drift.Value(_accountId!),
      );

      if (widget.booking == null && _notesController.text.isEmpty) {
        // -> Create case, merge is an option
        final mergeable = await db.bookingsDao.findMergeableBooking(companion);

        if (mergeable != null && mounted) {
          // -> Perform merge
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
            if (mounted) Navigator.of(context).pop();
            return;
          } else {
            if (await db.accountsDao.leadsToInconsistentBalanceHistory(
              newBooking: companion,
            )) {
              showToast(l10n.actionCancelledDueToDataInconsistency);
              return;
            }
            await db.bookingsDao.createBooking(companion);
          }
        } else {
          if (await db.accountsDao.leadsToInconsistentBalanceHistory(
            newBooking: companion,
          )) {
            showToast(l10n.actionCancelledDueToDataInconsistency);
            return;
          }
          await db.bookingsDao.createBooking(companion);
        }
      } else if (widget.booking == null) {
        // -> Create case, merge not an option
        if (await db.accountsDao.leadsToInconsistentBalanceHistory(
          newBooking: companion,
        )) {
          showToast(l10n.actionCancelledDueToDataInconsistency);
          return;
        }
        await db.bookingsDao.createBooking(companion);
      } else {
        if (await db.accountsDao.leadsToInconsistentBalanceHistory(
          originalBooking: widget.booking,
          newBooking: companion,
        )) {
          showToast(l10n.actionCancelledDueToDataInconsistency);
          return;
        }
        await db.bookingsDao.updateBooking(
          widget.booking!,
          companion.copyWith(id: drift.Value(widget.booking!.id)),
        );
      }

      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<AppDatabase>(context, listen: false);
    final currencyProvider = Provider.of<BaseCurrencyProvider>(context);
    final l10n = AppLocalizations.of(context)!;
    final validator = Validator(l10n);

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
                        validator: (_) => validator.validateDate(_date),
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
                          suffixText: currencyProvider.symbol,
                          errorMaxLines: 2,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            signed: true, decimal: true),
                        validator: (value) =>
                            validator.validateMaxTwoDecimalsNotZero(value),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Autocomplete<String>(
                  key: const Key('category_field'),
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return const Iterable<String>.empty();
                    }
                    return _distinctCategories.where((category) {
                      return category
                          .toLowerCase()
                          .contains(textEditingValue.text.toLowerCase());
                    });
                  },
                  onSelected: (String selection) {
                    setState(() {
                      _categoryController.text = selection;
                    });
                  },
                  fieldViewBuilder: (BuildContext context,
                      TextEditingController textEditingController,
                      FocusNode focusNode,
                      void Function() onFieldSubmitted) {
                    // For existing bookings, ensure the Autocomplete's internal controller
                    // reflects the initial category from _categoryController.
                    if (widget.booking != null &&
                        _categoryController.text.isNotEmpty &&
                        textEditingController.text !=
                            _categoryController.text) {
                      textEditingController.text = _categoryController.text;
                    }
                    return TextFormField(
                      controller: textEditingController,
                      focusNode: focusNode,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: l10n.category,
                        border: const OutlineInputBorder(),
                        errorMaxLines: 2,
                      ),
                      validator: (value) => validator.validateNotInitial(value),
                      onChanged: (value) {
                        _categoryController.text =
                            value; // Keep _categoryController in sync
                      },
                      onFieldSubmitted: (String value) {
                        onFieldSubmitted();
                        _categoryController.text =
                            value; // Also update on submit
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
                      validator: (value) =>
                          validator.validateAccountSelected(value),
                    );
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('notes_field'),
                  controller: _notesController,
                  textCapitalization: TextCapitalization.sentences,
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
