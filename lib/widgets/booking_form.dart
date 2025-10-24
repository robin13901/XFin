import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  bool _isTransfer = false;

  late DateTime _date;
  late TextEditingController _amountController;
  late TextEditingController _reasonController;
  late TextEditingController _notesController;
  late int? _sendingAccountId;
  late int? _receivingAccountId;
  late bool _excludeFromAverage;

  @override
  void initState() {
    super.initState();
    final booking = widget.booking;
    if (booking != null) {
      _date = DateTime.fromMillisecondsSinceEpoch(booking.date);
      _amountController = TextEditingController(text: booking.amount.toString());
      _reasonController = TextEditingController(text: booking.reason);
      _notesController = TextEditingController(text: booking.notes ?? '');
      _excludeFromAverage = booking.excludeFromAverage;
      
      // A booking is a transfer if and only if the sendingAccountId is not null.
      _isTransfer = booking.sendingAccountId != null;

      if (_isTransfer) {
        _sendingAccountId = booking.sendingAccountId;
        _receivingAccountId = booking.receivingAccountId;
      } else {
        // For entries (income/expense), only receiving account is relevant.
        _receivingAccountId = booking.receivingAccountId;
        _sendingAccountId = null;
      }
    } else {
      // Defaults for a new booking
      _date = DateTime.now();
      _amountController = TextEditingController();
      _reasonController = TextEditingController();
      _notesController = TextEditingController();
      _sendingAccountId = null;
      _receivingAccountId = null;
      _excludeFromAverage = false;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveForm() async {
    if (_formKey.currentState!.validate()) {
      final db = Provider.of<AppDatabase>(context, listen: false);
      final amount = double.parse(_amountController.text.replaceAll(',', '.'));

      final companion = BookingsCompanion(
        date: drift.Value(_date.millisecondsSinceEpoch),
        reason: drift.Value(_reasonController.text),
        notes: drift.Value(_notesController.text),
        excludeFromAverage: drift.Value(_excludeFromAverage),
        
        // Correct logic: sendingAccountId is ONLY for transfers.
        amount: drift.Value(_isTransfer ? amount.abs() : amount),
        sendingAccountId: drift.Value(_isTransfer ? _sendingAccountId : null),
        receivingAccountId: drift.Value(_receivingAccountId),
      );

      if (widget.booking == null) {
        await db.bookingsDao.createBooking(companion);
      } else {
        await db.bookingsDao.updateBookingWithBalance(
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
                Center(
                  child: ToggleButtons(
                    isSelected: [!_isTransfer, _isTransfer],
                    onPressed: (index) {
                      setState(() {
                        _isTransfer = index == 1;
                      });
                    },
                    borderRadius: BorderRadius.circular(8.0),
                    children: const [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text('Eintrag'),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text('Überweisung'),
                      ),
                    ],
                  ),
                ),
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
                        keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Bitte Betrag eingeben';
                          }
                          if (double.tryParse(value.replaceAll(',', '.')) == null) {
                            return 'Ungültiger Betrag';
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
                      return 'Bitte Grund eingeben';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                StreamBuilder<List<Account>>(
                  stream: db.accountsDao.watchAllAccounts(),
                  builder: (context, snapshot) {
                    final accounts = snapshot.data ?? [];
                    if (!_isTransfer) { // Entry Form
                      return DropdownButtonFormField<int>(
                        value: _receivingAccountId,
                        decoration: const InputDecoration(
                          labelText: 'Konto',
                          border: OutlineInputBorder(),
                        ),
                        items: accounts.map((account) {
                          return DropdownMenuItem(value: account.id, child: Text(account.name));
                        }).toList(),
                        onChanged: (value) => setState(() => _receivingAccountId = value),
                        validator: (value) => value == null ? 'Bitte Konto wählen' : null,
                      );
                    } else { // Transfer Form
                      return Column(
                        children: [
                          DropdownButtonFormField<int>(
                            value: _sendingAccountId,
                            decoration: const InputDecoration(labelText: 'Von Konto', border: OutlineInputBorder()),
                            items: accounts.map((account) {
                              return DropdownMenuItem(value: account.id, child: Text(account.name));
                            }).toList(),
                            onChanged: (value) => setState(() => _sendingAccountId = value),
                            validator: (value) {
                              if (value == null) return 'Bitte Konto wählen';
                              if (value == _receivingAccountId) return 'Konten müssen verschieden sein';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<int>(
                            value: _receivingAccountId,
                            decoration: const InputDecoration(labelText: 'Auf Konto', border: OutlineInputBorder()),
                            items: accounts.map((account) {
                              return DropdownMenuItem(value: account.id, child: Text(account.name));
                            }).toList(),
                            onChanged: (value) => setState(() => _receivingAccountId = value),
                            validator: (value) {
                              if (value == null) return 'Bitte Konto wählen';
                              if (value == _sendingAccountId) return 'Konten müssen verschieden sein';
                              return null;
                            },
                          ),
                        ],
                      );
                    }
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
