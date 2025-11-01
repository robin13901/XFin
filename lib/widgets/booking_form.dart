import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:oktoast/oktoast.dart';
import 'package:provider/provider.dart';
import 'package:xfin/database/app_database.dart';

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

  final _disallowedReasons = ['überweisung'];

  @override
  void initState() {
    super.initState();
    final booking = widget.booking;
    if (booking != null) {
      final dateString = booking.date.toString();
      _date = DateTime.parse(
          '${dateString.substring(0, 4)}-${dateString.substring(4, 6)}-${dateString.substring(6, 8)}');
      _amountController = TextEditingController(text: booking.amount.toString());
      _reasonController = TextEditingController(text: booking.reason);
      _notesController = TextEditingController(text: booking.notes);
      _excludeFromAverage = booking.excludeFromAverage;
      _isGenerated = booking.isGenerated;
      _accountId = booking.accountId;
    } else {
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
    super.dispose();
  }

  Future<void> _performMerge(AppDatabase db, Booking existing, BookingsCompanion newBooking) async {
    final mergedAmount = existing.amount + newBooking.amount.value;
    final updatedCompanion = existing.toCompanion(false).copyWith(amount: drift.Value(mergedAmount));
    await db.bookingsDao.updateBookingAndUpdateAccount(existing, updatedCompanion);
  }

  Future<void> _saveForm() async {
    if (_formKey.currentState!.validate()) {
      final db = Provider.of<AppDatabase>(context, listen: false);
      final amount = double.parse(_amountController.text.replaceAll(',', '.'));

      if (widget.booking == null) {
        // Only for new bookings
        if (_accountId != null && amount < 0) {
          final receivingAccount = await db.accountsDao.getAccount(_accountId!);
          if (receivingAccount.balance + amount < 0) {
            showToast('Konto hat nicht genügend Guthaben für diese Abbuchung.');
            return;
          }
        }
      }

      final dateAsInt = int.parse(DateFormat('yyyyMMdd').format(_date));
      final companion = BookingsCompanion(
        date: drift.Value(dateAsInt),
        reason: drift.Value(_reasonController.text.trim()),
        notes: drift.Value(_notesController.text.isEmpty ? null : _notesController.text),
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
              title: const Text('Buchungen zusammenführen?'),
              content: const Text('Eine ähnliche Buchung existiert bereits. Möchten Sie diese zusammenführen?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Neu erstellen'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Zusammenführen'),
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

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<AppDatabase>(context, listen: false);
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
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Datum',
                          border: const OutlineInputBorder(),
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
                          text: DateFormat.yMd().format(_date),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _amountController,
                        decoration: const InputDecoration(
                          labelText: 'Betrag',
                          border: OutlineInputBorder(),
                          suffixText: '€',
                        ),
                        keyboardType:
                          const TextInputType.numberWithOptions(signed: true, decimal: true),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Bitte gib einen Betrag an!';
                          }
                          final cleanValue = value.replaceAll(',', '.');
                          final amount = double.tryParse(cleanValue);
                          if (amount == null) {
                            return 'Ungültige Eingabe!';
                          }
                          if (RegExp(r'^-?\d+(\.\d{3,})$').hasMatch(cleanValue)) {
                            return 'Zu viele Nachkommastellen!';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Grund',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Bitte gib einen Grund an!';
                    }
                    if (_disallowedReasons.contains(value.trim().toLowerCase())) {
                      return 'Dieser Grund ist für Überweisungen reserviert.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                StreamBuilder<List<Account>>(
                  stream: db.accountsDao.watchAllAccounts(),
                  builder: (context, snapshot) {
                    final accounts = snapshot.data ?? [];
                    return DropdownButtonFormField<int>(
                      initialValue: _accountId,
                      decoration: const InputDecoration(
                        labelText: 'Konto',
                        border: OutlineInputBorder(),
                      ),
                      items: accounts.map((account) {
                        return DropdownMenuItem(value: account.id, child: Text(account.name));
                      }).toList(),
                      onChanged: (value) => setState(() => _accountId = value),
                      validator: (value) => value == null ? 'Bitte wähle ein Konto!' : null,
                    );
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(labelText: 'Notizen', border: OutlineInputBorder()),
                ),
                CheckboxListTile(
                  title: const Text('Vom Durchschnitt ausschließen'),
                  value: _excludeFromAverage,
                  onChanged: (value) => setState(() => _excludeFromAverage = value ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Abbrechen')),
                    const SizedBox(width: 8),
                    ElevatedButton(onPressed: _saveForm, child: const Text('Speichern')),
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
