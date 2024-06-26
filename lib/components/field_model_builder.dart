import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';

class FieldModelBuilder extends StatelessWidget {
  final List<String> fieldList;
  final List<String> typeList;
  final List<dynamic> valueList;
  final String? Function(String?)? validarItem;
  final BuildContext context;
  final Future<void> Function(BuildContext, int, TextEditingController)
      selecionarData;
  final void Function(int) onRemoveField; // Função para remover campos

  const FieldModelBuilder({
    super.key,
    required this.fieldList,
    required this.typeList,
    required this.valueList,
    required this.validarItem,
    required this.context,
    required this.selecionarData,
    required this.onRemoveField, // Parâmetro adicionado para remover campos
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        fieldList.length,
        (index) {
          return buildField(index);
        },
      ),
    );
  }

  Widget buildField(int index) {
    String fieldType = typeList[index];
    String labelText = fieldList[index];

    Widget formField;
    if (fieldType == 'Descrição') {
      formField = TextFormField(
        autovalidateMode: AutovalidateMode.onUserInteraction,
        decoration: InputDecoration(
          labelText: labelText,
          hintText: labelText,
        ),
        onSaved: (newValue) => valueList[index] = newValue!,
        validator: validarItem,
      );
    } else if (fieldType == 'Número Inteiro') {
      formField = TextFormField(
        autovalidateMode: AutovalidateMode.onUserInteraction,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          labelText: labelText,
          hintText: labelText,
        ),
        onSaved: (newValue) => valueList[index] = int.parse(newValue!),
        validator: validarItem,
      );
    } else if (fieldType == 'Número Decimal') {
      formField = TextFormField(
        autovalidateMode: AutovalidateMode.onUserInteraction,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d+\,?\d{0,2}'))
        ],
        decoration: InputDecoration(
          labelText: labelText,
          hintText: labelText,
        ),
        onSaved: (newValue) {
          double novoValor;
          if (!newValue!.contains(",")) {
            novoValor = double.parse("$newValue.0");
          } else {
            novoValor = double.parse(newValue.replaceAll(',', '.'));
          }
          valueList[index] = novoValor;
        },
        validator: validarItem,
      );
    } else if (fieldType == 'Calendário') {
      late TextEditingController dataController = TextEditingController(
          text: DateFormat('dd/MM/yyyy').format(valueList[index]));

      formField = TextFormField(
        readOnly: true,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^[0-9\/]*$')),
          LengthLimitingTextInputFormatter(10)
        ],
        controller: dataController,
        decoration: InputDecoration(
          labelText: labelText,
          suffixIcon: InkWell(
            onTap: () {
              selecionarData(context, index, dataController);
            },
            child: const Icon(Icons.calendar_today),
          ),
        ),
        onTap: () {
          selecionarData(context, index, dataController);
        },
        onSaved: (newValue) =>
            valueList[index] = DateFormat('dd/MM/yyyy').parse(newValue!),
        validator: validarItem,
      );
    } else if (fieldType == 'Dinheiro') {
      var moneyController = MoneyMaskedTextController(
        decimalSeparator: ',',
        thousandSeparator: '.',
        leftSymbol: 'R\$',
        precision: 2,
        initialValue: double.parse(valueList[index]
            .replaceAll(RegExp(r'[^\d,]'), '')
            .replaceAll(',', '.')),
      );
      formField = TextFormField(
        autovalidateMode: AutovalidateMode.onUserInteraction,
        keyboardType: TextInputType.number,
        controller: moneyController,
        decoration: InputDecoration(
          labelText: labelText,
          hintText: labelText,
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (value) => valueList[index] = value,
        onSaved: (newValue) => valueList[index] = newValue!,
        validator: validarItem,
      );
    } else {
      return const SizedBox();
    }

    return Row(
      children: [
        Expanded(child: formField),
        if (fieldList[index] !=
            'Nome') // Adiciona um botão de remoção, exceto para o campo "Nome"
          IconButton(
            icon: const Icon(Icons.remove_circle),
            onPressed: () => onRemoveField(index),
          ),
      ],
    );
  }
}
