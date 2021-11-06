// Runner Movement

#include "RunnerCommon.as"

void onInit(CMovement@ this)
{
	RunnerMoveVars moveVars;

	//Walking
	moveVars.walkSpeed = 2.9f;
	moveVars.walkSpeedInAir = 2.925f;
	moveVars.walkFactor = 1.0f;
	moveVars.walkLadderSpeed.Set(0.15f, 0.6f);
	//Jumping
	moveVars.jumpMaxVel = 2.9f * 1.3f;
	moveVars.jumpStart = 1.0f * 1.3f;
	moveVars.jumpMid = 0.55f * 1.3f;
	moveVars.jumpEnd = 0.4f * 1.3f;
	moveVars.jumpFactor = 1.0f;
	moveVars.jumpCount = 0;
	moveVars.canVault = true;
	//Swimming
	moveVars.swimspeed = 1.2;
	moveVars.swimforce = 30;
	moveVars.swimEdgeScale = 2.0f;
	//The overall scale of movement
	moveVars.overallScale = 1.0f;
	//Stopping forces
	moveVars.stoppingForce = 0.80f; //Function of mass
	moveVars.stoppingForceAir = 0.30f; //Function of mass
	moveVars.stoppingFactor = 1.0f;
	
	moveVars.walljumped = false;
	moveVars.walljumped_side = Walljump::NONE;
	moveVars.wallrun_length = 2;
	moveVars.wallrun_start = -1.0f;
	moveVars.wallrun_current = -1.0f;
	moveVars.wallclimbing = false;
	moveVars.wallsliding = false;

	CBlob@ blob = this.getBlob();
	CShape@ shape = blob.getShape();

	blob.set("moveVars", moveVars);
	shape.getVars().waterDragScale = 30.0f;
	shape.getConsts().collideWhenAttached = true;
}
