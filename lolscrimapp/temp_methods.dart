  import 'package:flutter/material.dart';
  Widget _buildBansSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2434),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF3C89E8), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bans de Champions',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.team.name,
                      style: const TextStyle(color: Color(0xFF0596AA), fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: List.generate(5, (index) => _buildBanSelector(myTeamBans, index)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentScrim.enemyTeamName,
                      style: const TextStyle(color: Color(0xFFC8534A), fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: List.generate(5, (index) => _buildBanSelector(enemyTeamBans, index)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBanSelector(List<Champion?> bans, int index) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => _showChampionDialog((champion) {
          setState(() {
            bans[index] = champion;
          });
        }),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF2A3F5F),
            border: Border.all(color: Colors.grey.shade600),
            borderRadius: BorderRadius.circular(4),
          ),
          child: bans[index] != null
              ? Center(
                  child: Text(
                    bans[index]!.name[0],
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                )
              : const Icon(Icons.block, color: Colors.grey, size: 20),
        ),
      ),
    );
  }

  Widget _buildObjectivesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2434),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF3C89E8), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Objectifs',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.team.name,
                      style: const TextStyle(color: Color(0xFF0596AA), fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _buildObjectiveInputs(true),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentScrim.enemyTeamName,
                      style: const TextStyle(color: Color(0xFFC8534A), fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _buildObjectiveInputs(false),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildObjectiveInputs(bool isMyTeam) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        _buildObjectiveInput('Tours', isMyTeam ? myTeamTurrets : enemyTeamTurrets, (val) {
          setState(() {
            if (isMyTeam) myTeamTurrets = val ?? 0;
            else enemyTeamTurrets = val ?? 0;
          });
        }),
        _buildObjectiveInput('Dragons', isMyTeam ? myTeamDragons : enemyTeamDragons, (val) {
          setState(() {
            if (isMyTeam) myTeamDragons = val ?? 0;
            else enemyTeamDragons = val ?? 0;
          });
        }),
        _buildObjectiveInput('Barons', isMyTeam ? myTeamBarons : enemyTeamBarons, (val) {
          setState(() {
            if (isMyTeam) myTeamBarons = val ?? 0;
            else enemyTeamBarons = val ?? 0;
          });
        }),
        _buildObjectiveInput('Heralds', isMyTeam ? myTeamHeralds : enemyTeamHeralds, (val) {
          setState(() {
            if (isMyTeam) myTeamHeralds = val ?? 0;
            else enemyTeamHeralds = val ?? 0;
          });
        }),
        _buildObjectiveInput('Grubs', isMyTeam ? myTeamGroms : enemyTeamGroms, (val) {
          setState(() {
            if (isMyTeam) myTeamGroms = val ?? 0;
            else enemyTeamGroms = val ?? 0;
          });
        }),
      ],
    );
  }

  Widget _buildObjectiveInput(String label, int value, Function(int?) onChanged) {
    return SizedBox(
      width: 80,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 4),
          TextFormField(
            initialValue: value.toString(),
            style: const TextStyle(color: Colors.white, fontSize: 12),
            decoration: const InputDecoration(
              isDense: true,
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.all(8),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (val) => onChanged(int.tryParse(val)),
          ),
        ],
      ),
    );
  }