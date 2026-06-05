import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:dropdown_search/dropdown_search.dart';

class AccountInfoPage extends StatefulWidget {
  final bool startInEditMode; // New parameter to control initial edit mode

  const AccountInfoPage({Key? key, this.startInEditMode = false}) : super(key: key);

  @override
  _AccountInfoPageState createState() => _AccountInfoPageState();
}

class _AccountInfoPageState extends State<AccountInfoPage> {
  User? user = FirebaseAuth.instance.currentUser;

  // User profile data
  String userName = "";
  String email = "";
  String dateOfBirth = "";
  String gender = "";
  String city = "";
  String state = "";
  String country = "";
  bool isEmailVerified = false;

  // UI state
  bool isLoading = true;
  late bool isEditing; // Set based on widget parameter

  // Form controllers
  final TextEditingController dateInputController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Gender selection
  String? _selectedGender;
  final List<String> genders = ['Male', 'Female', 'Other'];

  // Countries data
  final List<String> _countries = [
    'United States', 'Canada', 'United Kingdom', 'Australia', 'India',
    'Germany', 'France', 'Japan', 'China', 'Brazil', 'Mexico',
    'South Africa', 'Nigeria', 'Russia', 'Italy', 'Spain',
    'Saudi Arabia', 'UAE', 'Singapore', 'Malaysia'
  ];

  // States data by country
  final Map<String, List<String>> _statesByCountry = {
    'United States': [
      'Alabama', 'Alaska', 'Arizona', 'Arkansas', 'California',
      'Colorado', 'Connecticut', 'Delaware', 'Florida', 'Georgia',
      'Hawaii', 'Idaho', 'Illinois', 'Indiana', 'Iowa',
      'Kansas', 'Kentucky', 'Louisiana', 'Maine', 'Maryland',
      'Massachusetts', 'Michigan', 'Minnesota', 'Mississippi', 'Missouri',
      'Montana', 'Nebraska', 'Nevada', 'New Hampshire', 'New Jersey',
      'New Mexico', 'New York', 'North Carolina', 'North Dakota', 'Ohio',
      'Oklahoma', 'Oregon', 'Pennsylvania', 'Rhode Island', 'South Carolina',
      'South Dakota', 'Tennessee', 'Texas', 'Utah', 'Vermont',
      'Virginia', 'Washington', 'West Virginia', 'Wisconsin', 'Wyoming'
    ],
    'Canada': [
      'Alberta', 'British Columbia', 'Manitoba', 'New Brunswick', 'Newfoundland and Labrador',
      'Northwest Territories', 'Nova Scotia', 'Nunavut', 'Ontario', 'Prince Edward Island',
      'Quebec', 'Saskatchewan', 'Yukon'
    ],
    'United Kingdom': [
      'England', 'Scotland', 'Wales', 'Northern Ireland'
    ],
    'Australia': [
      'New South Wales', 'Victoria', 'Queensland', 'Western Australia',
      'South Australia', 'Tasmania', 'Australian Capital Territory', 'Northern Territory'
    ],
    'India': [
      'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh',
      'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jharkhand',
      'Karnataka', 'Kerala', 'Madhya Pradesh', 'Maharashtra', 'Manipur',
      'Meghalaya', 'Mizoram', 'Nagaland', 'Odisha', 'Punjab',
      'Rajasthan', 'Sikkim', 'Tamil Nadu', 'Telangana', 'Tripura',
      'Uttar Pradesh', 'Uttarakhand', 'West Bengal', 'Delhi', 'Jammu and Kashmir'
    ],
    'China': [
      'Beijing', 'Shanghai', 'Guangdong', 'Jiangsu', 'Zhejiang',
      'Shandong', 'Henan', 'Sichuan', 'Hubei', 'Fujian'
    ],
    'Germany': [
      'Baden-Württemberg', 'Bavaria', 'Berlin', 'Brandenburg', 'Bremen',
      'Hamburg', 'Hesse', 'Lower Saxony', 'Mecklenburg-Vorpommern', 'North Rhine-Westphalia',
      'Rhineland-Palatinate', 'Saarland', 'Saxony', 'Saxony-Anhalt', 'Schleswig-Holstein', 'Thuringia'
    ]
  };

  // Cities data by state
  final Map<String, List<String>> _citiesByState = {
    'California': [
      'Los Angeles', 'San Francisco', 'San Diego', 'San Jose', 'Oakland',
      'Sacramento', 'Fresno', 'Long Beach', 'Santa Ana', 'Bakersfield'
    ],
    'New York': [
      'New York City', 'Buffalo', 'Rochester', 'Yonkers', 'Syracuse',
      'Albany', 'New Rochelle', 'Mount Vernon', 'Schenectady', 'Utica'
    ],
    'Texas': [
      'Houston', 'San Antonio', 'Dallas', 'Austin', 'Fort Worth',
      'El Paso', 'Arlington', 'Corpus Christi', 'Plano', 'Laredo'
    ],
    'Florida': [
      'Jacksonville', 'Miami', 'Tampa', 'Orlando', 'St. Petersburg',
      'Hialeah', 'Tallahassee', 'Fort Lauderdale', 'Port St. Lucie', 'Cape Coral'
    ],
    'Maharashtra': [
      'Mumbai', 'Pune', 'Nagpur', 'Thane', 'Nashik',
      'Aurangabad', 'Solapur', 'Kolhapur', 'Amravati', 'Nanded'
    ],
    'Karnataka': [
      'Bengaluru', 'Mysuru', 'Hubballi-Dharwad', 'Mangaluru', 'Belagavi',
      'Kalaburagi', 'Vijayapura', 'Davanagere', 'Shivamogga', 'Tumakuru'
    ],
    'Tamil Nadu': [
      'Chennai', 'Coimbatore', 'Madurai', 'Tiruchirappalli', 'Salem',
      'Tirunelveli', 'Tiruppur', 'Erode', 'Vellore', 'Thoothukudi'
    ],
    'England': [
      'London', 'Birmingham', 'Manchester', 'Liverpool', 'Leeds',
      'Newcastle', 'Sheffield', 'Bristol', 'Nottingham', 'Leicester'
    ],
    'Scotland': [
      'Edinburgh', 'Glasgow', 'Aberdeen', 'Dundee', 'Inverness',
      'Stirling', 'Perth', 'St Andrews', 'Paisley', 'East Kilbride'
    ],
    'Ontario': [
      'Toronto', 'Ottawa', 'Mississauga', 'Brampton', 'Hamilton',
      'London', 'Markham', 'Vaughan', 'Kitchener', 'Windsor'
    ],
    'Quebec': [
      'Montreal', 'Quebec City', 'Laval', 'Gatineau', 'Longueuil',
      'Sherbrooke', 'Saguenay', 'Lévis', 'Trois-Rivières', 'Terrebonne'
    ],
    'Bavaria': [
      'Munich', 'Nuremberg', 'Augsburg', 'Regensburg', 'Ingolstadt',
      'Würzburg', 'Fürth', 'Erlangen', 'Bayreuth', 'Bamberg'
    ],
    'Berlin': [
      'Mitte', 'Friedrichshain-Kreuzberg', 'Pankow', 'Charlottenburg-Wilmersdorf', 'Spandau',
      'Steglitz-Zehlendorf', 'Tempelhof-Schöneberg', 'Neukölln', 'Treptow-Köpenick', 'Lichtenberg'
    ]
  };

  List<String> _states = [];
  List<String> _cities = [];

  @override
  void initState() {
    super.initState();
    isEditing = widget.startInEditMode; // Set initial edit mode based on parameter

    if (user != null) {
      setState(() {
        email = user!.email ?? "";
        isEmailVerified = user!.emailVerified;
      });
      _loadUserData();
    }
  }

  void _loadStatesForCountry(String selectedCountry) {
    setState(() {
      _states = _statesByCountry[selectedCountry] ?? [];
    });
  }

  void _loadCitiesForState(String selectedState) {
    setState(() {
      _cities = _citiesByState[selectedState] ?? [];
    });
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        if (userName.isNotEmpty)
          Text(
            userName,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
      ],
    );
  }

  bool _isValidDateFormat(String value) {
    try {
      DateFormat('d-M-y').parseStrict(value);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      String formattedDate = DateFormat('d-M-y').format(pickedDate);
      setState(() {
        dateInputController.text = formattedDate;
        dateOfBirth = formattedDate;
      });
    }
  }

  Widget _buildInputField(String label, String value) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: "Name",
            hintText: "Enter your name",
            border: InputBorder.none,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your name';
            }
            return null;
          },
        ),
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: DropdownSearch<String>(
          popupProps: PopupProps.menu(
            fit: FlexFit.loose,
          ),
          items: genders,
          dropdownDecoratorProps: const DropDownDecoratorProps(
            dropdownSearchDecoration: InputDecoration(
              labelText: "Gender",
              hintText: "Select Gender",
              border: InputBorder.none,
            ),
          ),
          onChanged: (newValue) {
            if (newValue != null) {
              setState(() {
                _selectedGender = newValue;
              });
            }
          },
          selectedItem: _selectedGender,
        ),
      ),
    );
  }

  Widget _buildDateOfBirthField() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextFormField(
          controller: dateInputController,
          decoration: const InputDecoration(
            labelText: "Date Of Birth (d-M-y)",
            hintText: "Enter your date of birth",
            border: InputBorder.none,
            suffixIcon: Icon(Icons.calendar_today),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your date of birth';
            }
            if (!_isValidDateFormat(value)) {
              return 'Please enter a valid date in d-M-y format';
            }
            return null;
          },
          readOnly: true,
          onTap: () {
            _selectDate(context);
          },
        ),
      ),
    );
  }

  Widget _buildCityDropdown() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: DropdownSearch<String>(
          popupProps: PopupProps.bottomSheet(
            showSearchBox: true,
            searchFieldProps: TextFieldProps(
              decoration: const InputDecoration(
                hintText: "Search city",
                border: OutlineInputBorder(),
              ),
            ),
          ),
          dropdownDecoratorProps: const DropDownDecoratorProps(
            dropdownSearchDecoration: InputDecoration(
              labelText: "City",
              hintText: "Select City",
              border: InputBorder.none,
            ),
          ),
          items: _cities,
          onChanged: (newValue) {
            if (newValue != null) {
              setState(() {
                city = newValue;
              });
            }
          },
          selectedItem: city.isEmpty ? null : city,
          enabled: country.isNotEmpty && state.isNotEmpty,
        ),
      ),
    );
  }

  Widget _buildStateDropdown() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: DropdownSearch<String>(
          popupProps: PopupProps.bottomSheet(
            showSearchBox: true,
            searchFieldProps: TextFieldProps(
              decoration: const InputDecoration(
                hintText: "Search state",
                border: OutlineInputBorder(),
              ),
            ),
          ),
          dropdownDecoratorProps: const DropDownDecoratorProps(
            dropdownSearchDecoration: InputDecoration(
              labelText: "State",
              hintText: "Select State",
              border: InputBorder.none,
            ),
          ),
          items: _states,
          onChanged: (newValue) {
            if (newValue != null) {
              _loadCitiesForState(newValue);
              setState(() {
                state = newValue;
                city = ""; // Reset city when state changes
              });
            }
          },
          selectedItem: state.isEmpty ? null : state,
          enabled: country.isNotEmpty,
        ),
      ),
    );
  }

  Widget _buildCountryDropdown() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: DropdownSearch<String>(
          popupProps: PopupProps.bottomSheet(
            showSearchBox: true,
            searchFieldProps: TextFieldProps(
              decoration: const InputDecoration(
                hintText: "Search country",
                border: OutlineInputBorder(),
              ),
            ),
          ),
          items: _countries,
          dropdownDecoratorProps: const DropDownDecoratorProps(
            dropdownSearchDecoration: InputDecoration(
              labelText: "Country",
              hintText: "Select Country",
              border: InputBorder.none,
            ),
          ),
          onChanged: (newValue) {
            if (newValue != null) {
              _loadStatesForCountry(newValue);
              setState(() {
                country = newValue;
                state = ""; // Reset state when country changes
                city = ""; // Reset city when country changes
              });
            }
          },
          selectedItem: country.isEmpty ? null : country,
        ),
      ),
    );
  }

  Future<void> _saveUserData() async {
    if (_formKey.currentState!.validate()) {
      if (_nameController.text.isEmpty ||
          _selectedGender == null ||
          country.isEmpty ||
          state.isEmpty ||
          city.isEmpty ||
          dateInputController.text.isEmpty) {
        Fluttertoast.showToast(msg: "Please fill in all fields");
        return;
      }

      setState(() {
        isLoading = true;
      });

      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .get();

        if (userDoc.exists) {
          await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
            'name': _nameController.text,
            'gender': _selectedGender,
            'country': country,
            'state': state,
            'city': city,
            'dateOfBirth': dateInputController.text,
            'email': email,
          });
        } else {
          await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
            'name': _nameController.text,
            'gender': _selectedGender,
            'country': country,
            'state': state,
            'city': city,
            'dateOfBirth': dateInputController.text,
            'email': email,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }

        setState(() {
          userName = _nameController.text;
          gender = _selectedGender!;
          dateOfBirth = dateInputController.text;
          isEditing = false;
        });

        Fluttertoast.showToast(msg: "Profile updated successfully!");
      } catch (e) {
        print("Error updating profile: $e");
        Fluttertoast.showToast(msg: "Failed to update profile: ${e.toString()}");
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _loadUserData() async {
    if (user != null) {
      setState(() {
        isLoading = true;
      });

      try {
        var userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .get();

        if (userDoc.exists) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          setState(() {
            userName = userData['name'] ?? "";
            _nameController.text = userName;
            email = userData['email'] ?? "";
            gender = userData['gender'] ?? "";
            _selectedGender = gender.isNotEmpty ? gender : null;
            country = userData['country'] ?? "";
            state = userData['state'] ?? "";
            city = userData['city'] ?? "";

            if (country.isNotEmpty) {
              _loadStatesForCountry(country);
              if (state.isNotEmpty) {
                _loadCitiesForState(state);
              }
            }

            dateOfBirth = userData['dateOfBirth'] ?? "";
            dateInputController.text = dateOfBirth;

            // Only override isEditing if not forced by widget parameter
            if (!widget.startInEditMode) {
              isEditing = !(userName.isNotEmpty &&
                  gender.isNotEmpty &&
                  country.isNotEmpty &&
                  state.isNotEmpty &&
                  city.isNotEmpty &&
                  dateOfBirth.isNotEmpty);
            }
          });
        } else {
          setState(() {
            isEditing = true; // New user, start in edit mode
          });
        }
      } catch (e) {
        print('Error loading user data: $e');
        Fluttertoast.showToast(msg: "Error loading data: ${e.toString()}");
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _toggleEditMode() {
    setState(() {
      isEditing = !isEditing;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Account Information"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildProfileHeader(),
              const SizedBox(height: 20),
              _buildInputField("Email", email),
              _buildInputField("Email Verified", isEmailVerified ? "Yes" : "No"),
              const SizedBox(height: 20),
              if (isEditing) ...[
                _buildNameField(),
                const SizedBox(height: 10),
                _buildGenderDropdown(),
                const SizedBox(height: 10),
                _buildDateOfBirthField(),
                const SizedBox(height: 10),
                _buildCountryDropdown(),
                const SizedBox(height: 10),
                _buildStateDropdown(),
                const SizedBox(height: 10),
                _buildCityDropdown(),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saveUserData,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          backgroundColor: Colors.green,
                        ),
                        child: const Text('Save', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                    if (userName.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _toggleEditMode,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            backgroundColor: Colors.red,
                          ),
                          child: const Text('Cancel', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ],
                ),
              ] else ...[
                _buildInputField("Name", userName),
                _buildInputField("Gender", gender),
                _buildInputField("Date of Birth", dateOfBirth),
                _buildInputField("Country", country),
                _buildInputField("State", state),
                _buildInputField("City", city),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _toggleEditMode,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          backgroundColor: Colors.blue,
                        ),
                        child: const Text('Edit Information', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}