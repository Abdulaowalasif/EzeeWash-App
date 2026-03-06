import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const primaryColor = Color(0xFF1D4BC7);
const primaryGradient = LinearGradient(
  colors: [Color(0xFF1D4BC7), Color(0xFF2F2E98)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

class AddressScreen extends StatefulWidget {
  const AddressScreen({super.key});

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  String selectedType = "Home";
  int? defaultIndex;

  final List<Map<String, String>> addresses = [];

  final TextEditingController streetController = TextEditingController();
  final TextEditingController cityController = TextEditingController();

  bool isEditing = false;
  int? editingIndex;

  void _addOrUpdateAddress() {
    if (streetController.text.trim().isEmpty || cityController.text.trim().isEmpty) return;

    setState(() {
      if (isEditing && editingIndex != null) {
        addresses[editingIndex!] = {
          "type": selectedType,
          "street": streetController.text.trim(),
          "city": cityController.text.trim(),
        };
        isEditing = false;
        editingIndex = null;
      } else {
        addresses.add({
          "type": selectedType,
          "street": streetController.text.trim(),
          "city": cityController.text.trim(),
        });
      }

      streetController.clear();
      cityController.clear();
      selectedType = "Home";
      FocusScope.of(context).unfocus();
    });
  }

  void _setDefault(int index) {
    setState(() {
      defaultIndex = index;
    });
  }

  void _deleteAddress(int index) {
    setState(() {
      addresses.removeAt(index);
      if (defaultIndex == index) defaultIndex = null;
      if (isEditing && editingIndex == index) {
        isEditing = false;
        editingIndex = null;
        streetController.clear();
        cityController.clear();
        selectedType = "Home";
      }
    });
  }

  void _editAddress(int index) {
    setState(() {
      streetController.text = addresses[index]["street"] ?? "";
      cityController.text = addresses[index]["city"] ?? "";
      selectedType = addresses[index]["type"] ?? "Home";
      isEditing = true;
      editingIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),

      /// -------- Gradient Header --------
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(20, 10, 20, 10),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: primaryGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 16),
                Text(
                  "Manage Addresses",
                  style: GoogleFonts.alexandria(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      /// -------- Body --------
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),

                /// -------- Add New Address Card --------
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade100),
                    boxShadow: isDark ? [] : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEditing ? "Update Address" : "Add New Address",
                        style: GoogleFonts.alexandria(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 16),

                      /// Address Type Selection
                      Row(
                        children: ["Home", "Work", "Other"].map((type) {
                          bool isChipSelected = selectedType == type;
                          return Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: ChoiceChip(
                              label: Text(type),
                              selected: isChipSelected,
                              onSelected: (_) => setState(() => selectedType = type),
                              backgroundColor: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                              selectedColor: primaryColor,
                              labelStyle: GoogleFonts.alexandria(
                                fontSize: 12,
                                color: isChipSelected ? Colors.white : (isDark ? Colors.grey : Colors.black87),
                                fontWeight: isChipSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              side: BorderSide.none,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      _buildTextField(streetController, "Street Address", Icons.map_outlined, isDark),
                      const SizedBox(height: 12),
                      _buildTextField(cityController, "City, Division, ZIP Code", Icons.location_city_rounded, isDark),

                      const SizedBox(height: 20),

                      /// Add / Update Button
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: primaryGradient,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: _addOrUpdateAddress,
                          icon: Icon(isEditing ? Icons.update_rounded : Icons.add_rounded, color: Colors.white, size: 20),
                          label: Text(
                            isEditing ? "Update Address" : "Add Address",
                            style: GoogleFonts.alexandria(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                Text(
                  "Saved Addresses",
                  style: GoogleFonts.alexandria(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),

                const SizedBox(height: 16),

                /// -------- Address List --------
                if (addresses.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Text("No addresses saved yet.", style: GoogleFonts.alexandria(color: Colors.grey)),
                    ),
                  ),

                ...List.generate(addresses.length, (index) {
                  final item = addresses[index];
                  bool isDefault = defaultIndex == index;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDefault ? primaryColor : (isDark ? Colors.white10 : Colors.grey.shade100),
                        width: isDefault ? 2 : 1,
                      ),
                      boxShadow: isDark ? [] : [
                        BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 6)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                item["type"] == "Home" ? Icons.home_rounded : item["type"] == "Work" ? Icons.work_rounded : Icons.location_on_rounded,
                                size: 18,
                                color: primaryColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              item["type"] ?? "",
                              style: GoogleFonts.alexandria(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () => _editAddress(index),
                              icon: const Icon(Icons.edit_note_rounded, color: Color(0xFF1D4BC7), size: 24),
                              visualDensity: VisualDensity.compact,
                            ),
                            IconButton(
                              onPressed: () => _deleteAddress(index),
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "${item["street"]},\n${item["city"]}",
                          style: GoogleFonts.alexandria(
                            fontSize: 14,
                            height: 1.5,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 20),

                        /// Default Button
                        SizedBox(
                          width: double.infinity,
                          child: isDefault
                              ? Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF10B981).withOpacity(0.5)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  "Default Address",
                                  style: GoogleFonts.alexandria(color: const Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ],
                            ),
                          )
                              : OutlinedButton(
                            onPressed: () => _setDefault(index),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: primaryColor, width: 1.5),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(
                              "Set as Default",
                              style: GoogleFonts.alexandria(color: primaryColor, fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, bool isDark) {
    return TextField(
      controller: controller,
      style: GoogleFonts.alexandria(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: isDark ? Colors.grey.shade500 : Colors.grey.shade400, fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
        filled: true,
        fillColor: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primaryColor, width: 1.5)),
      ),
    );
  }
}