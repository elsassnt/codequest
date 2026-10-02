import 'dart:convert';

class Pt {
  final int x, y;
  const Pt(this.x, this.y);

  @override
  bool operator ==(Object o) => o is Pt && o.x == x && o.y == y;
  @override
  int get hashCode => x * 1000 + y;

  List<int> toJson() => [x, y];
  factory Pt.fromJson(dynamic j) => Pt(j[0] as int, j[1] as int);
}

class Mission {
  final int id;
  final String title, description, material, starterCode;
  final String requiredPattern, requiredMessage;
  final int gridW, gridH, startX, startY, finishX, finishY;
  final int optimalLines, rewardScore;
  final List<Pt> coins, obstacles;
  final List<String> hints;

  const Mission({
    required this.id,
    required this.title,
    required this.description,
    required this.material,
    required this.gridW,
    required this.gridH,
    required this.startX,
    required this.startY,
    required this.finishX,
    required this.finishY,
    this.coins = const [],
    this.obstacles = const [],
    required this.optimalLines,
    this.rewardScore = 50,
    required this.hints,
    this.starterCode = '',
    required this.requiredPattern,
    required this.requiredMessage,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'material': material,
        'grid_width': gridW,
        'grid_height': gridH,
        'start_x': startX,
        'start_y': startY,
        'finish_x': finishX,
        'finish_y': finishY,
        'coins_json': jsonEncode(coins.map((e) => e.toJson()).toList()),
        'obstacles_json': jsonEncode(obstacles.map((e) => e.toJson()).toList()),
        'optimal_lines': optimalLines,
        'reward_score': rewardScore,
        'hint': hints.join('||'),
        'starter_code': starterCode,
        'required_pattern': requiredPattern,
        'required_message': requiredMessage,
      };

  factory Mission.fromMap(Map<String, Object?> m) {
    List<Pt> pts(Object? raw) => raw == null
        ? <Pt>[]
        : (jsonDecode(raw as String) as List).map(Pt.fromJson).toList();
    return Mission(
      id: m['id'] as int,
      title: m['title'] as String,
      description: m['description'] as String,
      material: m['material'] as String,
      gridW: m['grid_width'] as int,
      gridH: m['grid_height'] as int,
      startX: m['start_x'] as int,
      startY: m['start_y'] as int,
      finishX: m['finish_x'] as int,
      finishY: m['finish_y'] as int,
      coins: pts(m['coins_json']),
      obstacles: pts(m['obstacles_json']),
      optimalLines: m['optimal_lines'] as int,
      rewardScore: m['reward_score'] as int,
      hints: ((m['hint'] as String?) ?? '').split('||'),
      starterCode: (m['starter_code'] as String?) ?? '',
      requiredPattern: (m['required_pattern'] as String?) ?? '',
      requiredMessage: (m['required_message'] as String?) ?? '',
    );
  }
}
