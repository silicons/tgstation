//Defaults
#define MOVE_FORCE_DEFAULT 100
#define MOVE_RESIST_DEFAULT 100
#define PULL_FORCE_DEFAULT 100

//Factors/modifiers
#define MOVE_FORCE_PULL_RATIO 1				//Same move force to pull objects
#define MOVE_FORCE_PUSH_RATIO 1				//Same move force to normally push
#define MOVE_FORCE_FORCEPUSH_RATIO 2		//2x move force to forcefully push
#define MOVE_FORCE_CRUSH_RATIO 3			//3x move force to do things like crush objects

#define MOVE_FORCE_RESIST_MEGAFAUNA MOVE_RESIST_DEFAULT * MOVE_FORCE_CRUSH_RATIO * 11
#define MOVE_FORCE_RESIST_STATUE MOVE_RESIST_DEFAULT * MOVE_FORCE_CRUSH_RATIO * 11
#define MOVE_FORCE_RESIST_GOLIATH MOVE_RESIST_DEFAULT * MOVE_FORCE_CRUSH_RATIO * 6
#define MOVE_FORCE_RESIST_SPAWNER MOVE_RESIST_DEFAULT * 30

#define MOVE_FORCE_MULEBOT 200
#define MOVE_RESIST_MULEBOT 300

#define MOVE_RESIST_AI_BOLTED 500
#define MOVE_RESIST_AI_UNBOLTED 100

#define MOVE_RESIST_REVENANT 500
