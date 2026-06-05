import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../config/api_keys.dart';
import 'dart:math' as math;

class BackgroundHelper {
  static final BackgroundHelper _instance = BackgroundHelper._internal();
  factory BackgroundHelper() => _instance;
  BackgroundHelper._internal();

  final String _pixabayApiUrl = 'https://pixabay.com/api/';
  final Map<String, String> _backgroundCache = {};

  Future<String> getRandomBackground() async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_pixabayApiUrl?key=${ApiKeys.pixabayApiKey}&q=nature+peaceful+scenic&image_type=photo&orientation=horizontal&per_page=50',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['hits'] != null && data['hits'].isNotEmpty) {
          final randomIndex = math.Random().nextInt(data['hits'].length);
          final url = data['hits'][randomIndex]['largeImageURL'];
          debugPrint('Random background fetched: $url');
          return url;
        }
      }
      debugPrint('Error fetching random background: ${response.statusCode}');
      return _getDefaultBackground('default');
    } catch (e) {
      debugPrint('Exception in getRandomBackground: $e');
      return _getDefaultBackground('default');
    }
  }

  Future<String> getBackgroundForHabit(String habitName) async {
    try {
      // Normalize habit name for cache check
      final normalizedHabitName = habitName.toLowerCase().trim();
      if (_backgroundCache.containsKey(normalizedHabitName)) {
        debugPrint('Cache hit for $normalizedHabitName: ${_backgroundCache[normalizedHabitName]}');
        return _backgroundCache[normalizedHabitName]!;
      }

      final query = _getQueryForHabit(normalizedHabitName);
      final category = _getCategoryForHabit(normalizedHabitName);

      debugPrint('Fetching background for $normalizedHabitName with query: $query, category: $category');

      final response = await http.get(
        Uri.parse(
            '$_pixabayApiUrl?key=${ApiKeys.pixabayApiKey}'
                '&q=$query'
                '&image_type=photo'
                '&orientation=horizontal'
                '&per_page=20'
                '&safesearch=true'
                '&category=$category'
                '&min_width=1920'
                '&order=popular'
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['hits'] != null && data['hits'].isNotEmpty) {
          final topHits = data['hits'].take(5).toList();
          final randomIndex = math.Random().nextInt(topHits.length);
          final imageUrl = topHits[randomIndex]['largeImageURL'];
          _backgroundCache[normalizedHabitName] = imageUrl;
          debugPrint('Background fetched for $normalizedHabitName: $imageUrl');
          return imageUrl;
        } else {
          debugPrint('No hits for $normalizedHabitName with query: $query, category: $category');
        }
      } else {
        debugPrint('Error fetching background for $normalizedHabitName: ${response.statusCode}');
      }
      return _getDefaultBackground(normalizedHabitName);
    } catch (e) {
      debugPrint('Exception in getBackgroundForHabit for $habitName: $e');
      return _getDefaultBackground(habitName);
    }
  }

  String _getQueryForHabit(String habitName) {
    final normalizedHabitName = habitName.toLowerCase().trim();

    // Expanded query map with explicit "drink water" support
    final queries = {
      // Health & Fitness
      'meditation': 'zen+meditation+calm+serene',
      'exercise': 'fitness+exercise+gym+active',
      'yoga': 'yoga+pose+wellness+meditation',
      'walking': 'nature+trail+walking+hiking',
      'running': 'runner+track+athletics+outdoors',
      'cycling': 'bicycle+cycling+road+nature',
      'swimming': 'swimming+pool+water+sport',
      'gym': 'gym+weights+fitness+training',
      'workout': 'workout+training+exercise+energy',
      'stretching': 'stretching+yoga+flexibility+wellness',
      'pilates': 'pilates+mat+exercise+core',
      'drink water': 'water+glass+hydration+refreshing', // Exact match for "Drink Water"
      'drinking water': 'water+glass+hydration+refreshing', // Explicit match
      'jogging': 'jogging+park+outdoors+health',
      'weightlifting': 'weightlifting+gym+strength+muscle',
      'cardio': 'cardio+running+energy+fitness',
      'boxing': 'boxing+ring+gloves+sport',
      'dancing': 'dance+movement+performance+energy',
      'hiking': 'hiking+mountain+trail+adventure',
      'rock climbing': 'rock+climbing+adventure+sport',
      'surfing': 'surfing+wave+ocean+beach',

      // Mental & Educational
      'reading': 'book+reading+library+quiet',
      'studying': 'study+desk+books+education',
      'writing': 'writing+pen+notebook+creative',
      'learning': 'learning+education+classroom+focus',
      'journaling': 'journal+writing+reflection+calm',
      'mindfulness': 'mindfulness+peace+zen+relaxation',
      'brainstorming': 'ideas+brainstorm+creative+notes',
      'researching': 'research+library+books+knowledge',
      'math': 'math+equations+chalkboard+learning',
      'language': 'language+books+learning+words',
      'history': 'history+books+ancient+knowledge',
      'science': 'science+lab+experiment+discovery',

      // Creative & Artistic
      'painting': 'painting+canvas+art+colors',
      'drawing': 'drawing+sketch+pencil+art',
      'music': 'music+instrument+piano+melody',
      'singing': 'singing+microphone+music+voice',
      'photography': 'photography+camera+landscape+art',
      'sculpting': 'sculpture+clay+art+creative',
      'sewing': 'sewing+fabric+craft+design',
      'knitting': 'knitting+yarn+craft+cozy',
      'pottery': 'pottery+clay+ceramic+art',
      'calligraphy': 'calligraphy+pen+ink+art',
      'filmmaking': 'filmmaking+camera+cinema+creative',

      // Tech & Professional
      'coding': 'coding+computer+programming+tech',
      'programming': 'programming+code+developer+screen',
      'development': 'software+development+tech+modern',
      'software': 'software+computer+workspace+tech',
      'designing': 'design+creative+graphic+art',
      'writing code': 'code+programming+computer+modern',
      'testing': 'testing+software+tech+screen',
      'debugging': 'debugging+code+computer+tech',
      'data analysis': 'data+charts+analysis+tech',
      'networking': 'networking+business+meeting+people',

      // Home & Lifestyle
      'cooking': 'cooking+kitchen+food+chef',
      'baking': 'baking+oven+pastry+kitchen',
      'gardening': 'gardening+plants+flowers+nature',
      'cleaning': 'cleaning+home+tidy+organize',
      'organizing': 'organizing+minimal+home+tidy',
      'decorating': 'decor+interior+home+design',
      'laundry': 'laundry+washing+clean+home',
      'shopping': 'shopping+market+bags+lifestyle',
      'meal prep': 'meal+prep+kitchen+food',
      'home repair': 'home+repair+tools+fix',

      // Self-Care
      'sleeping': 'sleep+bed+rest+peaceful',
      'skincare': 'skincare+beauty+wellness+spa',
      'relaxing': 'relaxation+calm+peace+spa',
      'self care': 'selfcare+wellness+relax+spa',
      'beauty': 'beauty+care+wellness+mirror',
      'bathing': 'bath+relax+spa+water',
      'massage': 'massage+wellness+relax+calm',
      'meditating': 'meditation+zen+calm+peace',
      'breathing': 'breathing+relax+yoga+calm',

      // Social & Communication
      'presenting': 'presentation+meeting+business+slide',
      'public speaking': 'speech+stage+audience+confidence',
      'teaching': 'teaching+classroom+education+chalkboard',
      'calling': 'phone+call+communication+modern',
      'messaging': 'messaging+phone+chat+social',
      'teamwork': 'teamwork+meeting+collaboration+people',
      'mentoring': 'mentoring+teaching+guidance+people',

      // Productivity
      'planning': 'planning+planner+desk+organize',
      'goal setting': 'goals+motivation+success+plan',
      'time management': 'clock+time+organize+productivity',
      'task management': 'tasks+checklist+productivity+plan',
      'scheduling': 'schedule+calendar+organize+time',
      'prioritizing': 'priority+list+organize+work',

      // Hobbies
      'crafting': 'crafting+handmade+creative+tools',
      'woodworking': 'woodworking+tools+workshop+craft',
      'collecting': 'collection+hobby+display+items',
      'gaming': 'gaming+controller+tech+fun',
      'fishing': 'fishing+lake+nature+calm',
      'bird watching': 'bird+watching+nature+calm',
      'puzzle': 'puzzle+jigsaw+game+focus',

      // Outdoor Activities
      'camping': 'camping+tent+nature+outdoors',
      'skateboarding': 'skateboarding+urban+sport+action',
      'kayaking': 'kayaking+water+adventure+nature',
      'sailing': 'sailing+boat+ocean+adventure',

      // Routines
      'morning': 'morning+sunrise+calm+peaceful',
      'evening': 'evening+sunset+relax+calm',
      'night': 'night+stars+calm+peaceful',
    };

    // Exact match
    if (queries.containsKey(normalizedHabitName)) {
      debugPrint('Exact query match for $normalizedHabitName: ${queries[normalizedHabitName]}');
      return queries[normalizedHabitName]!;
    }

    // Partial match with longest keyword
    String? bestMatch;
    int maxMatchLength = 0;
    for (var entry in queries.entries) {
      if (normalizedHabitName.contains(entry.key) && entry.key.length > maxMatchLength) {
        maxMatchLength = entry.key.length;
        bestMatch = entry.value;
      }
    }
    if (bestMatch != null) {
      debugPrint('Partial query match for $normalizedHabitName: $bestMatch');
      return bestMatch;
    }

    // Fallback: Use habit name with contextual keywords
    final words = normalizedHabitName.split(' ');
    final fallbackQuery = '${words.join('+')}+activity+scene';
    debugPrint('Fallback query for $normalizedHabitName: $fallbackQuery');
    return fallbackQuery;
  }

  String _getCategoryForHabit(String habitName) {
    final lowerHabit = habitName.toLowerCase();

    if (lowerHabit.contains('cod') || lowerHabit.contains('tech') || lowerHabit.contains('programming') || lowerHabit.contains('software') || lowerHabit.contains('designing')) {
      return 'computer';
    } else if (lowerHabit.contains('food') || lowerHabit.contains('cooking') || lowerHabit.contains('baking')) {
      return 'food';
    } else if (lowerHabit.contains('nature') || lowerHabit.contains('outdoor') || lowerHabit.contains('hiking') || lowerHabit.contains('camping')) {
      return 'nature';
    } else if (lowerHabit.contains('sport') || lowerHabit.contains('fitness') || lowerHabit.contains('exercise') || lowerHabit.contains('yoga') || lowerHabit.contains('workout')) {
      return 'sports';
    } else if (lowerHabit.contains('art') || lowerHabit.contains('painting') || lowerHabit.contains('drawing') || lowerHabit.contains('music') || lowerHabit.contains('photography')) {
      return 'art';
    } else if (lowerHabit.contains('study') || lowerHabit.contains('reading') || lowerHabit.contains('learning') || lowerHabit.contains('writing')) {
      return 'education';
    } else if (lowerHabit.contains('sleep') || lowerHabit.contains('relax') || lowerHabit.contains('self') || lowerHabit.contains('skincare') || lowerHabit.contains('beauty') || lowerHabit.contains('drink') || lowerHabit.contains('water')) {
      return 'health'; // Explicitly include "drink" and "water" in health category
    } else if (lowerHabit.contains('home') || lowerHabit.contains('clean') || lowerHabit.contains('organize') || lowerHabit.contains('decor') || lowerHabit.contains('garden')) {
      return 'backgrounds';
    } else if (lowerHabit.contains('morning') || lowerHabit.contains('evening')) {
      return 'nature';
    }

    return 'backgrounds';
  }

  String _getDefaultBackground(String habitName) {
    final defaults = {
      'meditation': 'https://cdn.pixabay.com/photo/2016/11/18/13/47/meditation-1834716_1280.jpg',
      'exercise': 'https://cdn.pixabay.com/photo/2016/11/18/13/03/fitness-1834827_1280.jpg',
      'reading': 'https://cdn.pixabay.com/photo/2016/11/18/13/47/book-1834743_1280.jpg',
      'studying': 'https://cdn.pixabay.com/photo/2016/11/18/13/47/laptop-1834742_1280.jpg',
      'yoga': 'https://cdn.pixabay.com/photo/2016/11/18/13/47/yoga-1834734_1280.jpg',
      'coding': 'https://cdn.pixabay.com/photo/2016/11/19/14/00/code-1839406_1280.jpg',
      'cooking': 'https://cdn.pixabay.com/photo/2016/11/18/13/47/kitchen-1834750_1280.jpg',
      'gardening': 'https://cdn.pixabay.com/photo/2016/11/18/13/47/garden-1834738_1280.jpg',
      'morning': 'https://cdn.pixabay.com/photo/2016/11/18/13/47/sunrise-1834728_1280.jpg',
      'evening': 'https://cdn.pixabay.com/photo/2016/11/18/13/47/sunset-1834729_1280.jpg',
      'drink water': 'https://cdn.pixabay.com/photo/2016/11/18/13/47/water-1834762_1280.jpg', // Exact match for "Drink Water"
      'drinking water': 'https://cdn.pixabay.com/photo/2016/11/18/13/47/water-1834762_1280.jpg',
      'walking': 'https://cdn.pixabay.com/photo/2016/11/18/13/47/path-1834732_1280.jpg',
      'running': 'https://cdn.pixabay.com/photo/2016/11/18/13/47/running-1834758_1280.jpg',
      'swimming': 'https://cdn.pixabay.com/photo/2016/11/18/13/47/swimming-1834760_1280.jpg',
      'painting': 'https://cdn.pixabay.com/photo/2016/11/18/13/47/painting-1834748_1280.jpg',
      'music': 'https://cdn.pixabay.com/photo/2016/11/18/13/47/piano-1834756_1280.jpg',
      'boxing': 'https://cdn.pixabay.com/photo/2016/11/22/22/43/boxer-1851417_1280.jpg',
      'hiking': 'https://cdn.pixabay.com/photo/2016/11/18/13/47/mountain-1834720_1280.jpg',
      'photography': 'https://cdn.pixabay.com/photo/2016/11/18/13/47/camera-1834736_1280.jpg',
      'writing': 'https://cdn.pixabay.com/photo/2016/11/18/13/47/notebook-1834745_1280.jpg',
      'cleaning': 'https://cdn.pixabay.com/photo/2016/11/18/13/47/clean-1834737_1280.jpg',
      'sleeping': 'https://cdn.pixabay.com/photo/2016/11/18/13/47/bed-1834735_1280.jpg',
      'gaming': 'https://cdn.pixabay.com/photo/2016/11/18/13/47/game-1834739_1280.jpg',
      'fishing': 'https://cdn.pixabay.com/photo/2016/11/18/13/47/fishing-1834740_1280.jpg',
      'camping': 'https://cdn.pixabay.com/photo/2016/11/18/13/47/camping-1834733_1280.jpg',
      'puzzle': 'https://cdn.pixabay.com/photo/2016/11/18/13/47/puzzle-1834747_1280.jpg',
      'default': 'https://cdn.pixabay.com/photo/2016/11/18/13/47/mountains-1834721_1280.jpg',
    };

    final lowerHabit = habitName.toLowerCase().trim();
    for (var key in defaults.keys) {
      if (lowerHabit == key) { // Exact match first
        debugPrint('Exact default background match for $lowerHabit: ${defaults[key]}');
        return defaults[key]!;
      }
    }
    for (var key in defaults.keys) {
      if (lowerHabit.contains(key)) { // Partial match as fallback
        debugPrint('Partial default background match for $lowerHabit: ${defaults[key]}');
        return defaults[key]!;
      }
    }
    debugPrint('Using default background for $lowerHabit: ${defaults['default']}');
    return defaults['default']!;
  }

  void clearCache() {
    _backgroundCache.clear();
    debugPrint('Background cache cleared');
  }
}