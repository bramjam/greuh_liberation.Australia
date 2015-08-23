private [ "_spawnsector", "_grp", "_usable_sectors", "_spawntype", "_civnumber", "_vehdriver", "_spawnpos", "_civveh", "_sectors_patrol",
		"_patrol_startpos", "_waypoint", "_grpspeed", "_sectors_patrol_random", "_sectorcount", "_nextsector", "_nearestroad" ];

_civveh = objNull;

sleep (150 + (random 150));
_spawnsector = "";

if ( isNil "active_sectors" ) then { active_sectors = [] };

while { endgame == 0 } do {

	_spawnsector = "";
	_usable_sectors = [];
	{
		if ( ( ( [ getmarkerpos _x , 1000 , WEST ] call F_getUnitsCount ) == 0 ) && ( count ( [ getmarkerpos _x , 3500 ] call F_getNearbyPlayers ) > 0 ) ) then {
			_usable_sectors pushback _x;
		}

	} foreach ((sectors_bigtown + sectors_capture + sectors_factory) - (active_sectors));

	if ( count _usable_sectors > 0 ) then {
		_spawnsector = _usable_sectors call BIS_fnc_selectRandom;

		_grp = createGroup CIVILIAN;
		if ( random 100 < 33) then {
			_civnumber = 1 + (floor (random 2));
			while { count units _grp < _civnumber } do {
				( civilians call BIS_fnc_selectRandom ) createUnit [ markerpos _spawnsector, _grp, "this addMPEventHandler [""MPKilled"", {_this spawn kill_manager}]", 0.5, "private"];
			};
			_grpspeed = "LIMITED";
		} else {

			_nearestroad = objNull;
			while { isNull _nearestroad } do {
				_nearestroad = [ [  getmarkerpos (_spawnsector), random(100), random(360)  ] call BIS_fnc_relPos, 200, [] ] call BIS_fnc_nearestRoad;
				sleep 1;
			};

			_spawnpos = getpos _nearestroad;

			( civilians call BIS_fnc_selectRandom ) createUnit [ _spawnpos, _grp, "this addMPEventHandler [""MPKilled"", {_this spawn kill_manager}]", 0.5, "private"];
			_civveh = ( civilian_vehicles call BIS_fnc_selectRandom ) createVehicle _spawnpos;
			_civveh setpos _spawnpos;
			_civveh addMPEventHandler ['MPKilled', {_this spawn kill_manager}];
			_civveh addEventHandler ["HandleDamage", { private [ "_damage" ]; if (( side (_this select 3) != WEST ) && ( side (_this select 3) != EAST )) then { _damage = 0 } else { _damage = _this select 2 }; _damage } ];
			((units _grp) select 0) moveInDriver _civveh;
			((units _grp) select 0) disableAI "FSM";
			_grpspeed = "LIMITED"; // Until BIS does something to prevent civilians drivers from killing themselves all the time

		};

		{ _x addEventHandler ["HandleDamage", { private [ "_damage" ]; if (( side (_this select 3) != WEST ) && ( side (_this select 3) != EAST )) then { _damage = 0 } else { _damage = _this select 2 }; _damage } ]; } foreach units _grp;

		_sectors_patrol = [];
		_patrol_startpos = getpos (leader _grp);
		{
			if ( (_patrol_startpos distance (markerpos _x) < 5000 ) && ( count ( [ getmarkerpos _x , 4000 ] call F_getNearbyPlayers ) > 0 ) ) then {
				_sectors_patrol pushback _x;
			};
		} foreach (sectors_bigtown + sectors_capture + sectors_factory);

		_sectors_patrol_random = [];
		_sectorcount = count _sectors_patrol;
		while { count _sectors_patrol_random < _sectorcount } do {
			_nextsector = _sectors_patrol call BIS_fnc_selectRandom;
			_sectors_patrol_random pushback _nextsector;
			_sectors_patrol = _sectors_patrol - [_nextsector];

		};

		while {(count (waypoints _grp)) != 0} do {deleteWaypoint ((waypoints _grp) select 0);};
		{_x doFollow leader _grp} foreach units _grp;

		{
			_nearestroad = [ [  getmarkerpos (_x), random(100), random(360)  ] call BIS_fnc_relPos, 200, [] ] call BIS_fnc_nearestRoad;
			if ( isNull _nearestroad ) then {
				_waypoint = _grp addWaypoint [ markerpos _x, 100 ];
			} else {
				_waypoint = _grp addWaypoint [ getpos _nearestroad, 0 ];
			};
			_waypoint setWaypointType "MOVE";
			_waypoint setWaypointSpeed _grpspeed;
			_waypoint setWaypointBehaviour "SAFE";
			_waypoint setWaypointCombatMode "BLUE";
			_waypoint setWaypointCompletionRadius 100;
		} foreach _sectors_patrol_random;

		_waypoint = _grp addWaypoint [_patrol_startpos , 100];
		_waypoint setWaypointType "CYCLE";

		waitUntil {
			sleep (30 + (random 30));
			( ( ( { alive _x } count ( units _grp ) ) == 0 ) || ( count ( [ getpos leader _grp , 4000 ] call F_getNearbyPlayers ) == 0 ) )
		};

		if ( count ( [ getpos leader _grp , 4000 ] call F_getNearbyPlayers ) == 0 ) then {
			if ( !(isNull _civveh) ) then { deleteVehicle _civveh };
			{ deletevehicle _x } foreach units _grp;
		};
	};

	sleep 150 + (random (150));
};