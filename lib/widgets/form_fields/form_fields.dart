import 'package:flutter/material.dart';
import 'package:xfin/l10n/app_localizations.dart';

import '../../utils/validators.dart';

export 'date_fields.dart';
export 'dropdown_fields.dart';
export 'layout_fields.dart';
export 'text_fields.dart';

import 'date_fields.dart';
import 'dropdown_fields.dart';
import 'layout_fields.dart';
import 'text_fields.dart';

class FormFields with DateFieldsMixin, DropdownFieldsMixin, TextFieldsMixin, LayoutFieldsMixin {
  @override
  final AppLocalizations l10n;
  @override
  final Validator validator;
  @override
  final BuildContext formContext;

  FormFields(this.l10n, this.validator, this.formContext);
}
