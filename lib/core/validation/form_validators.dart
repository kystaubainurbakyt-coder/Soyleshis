class FormValidators {
  FormValidators._();

  static String? required(String? value) =>
      value == null || value.trim().isEmpty ? 'Өрісті толтырыңыз' : null;

  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) return 'Атыңызды енгізіңіз';
    return value.trim().length < 2 ? 'Атыңыз кемінде 2 таңба болсын' : null;
  }
}
