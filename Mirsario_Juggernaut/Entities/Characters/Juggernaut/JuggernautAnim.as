#include "JuggernautCommon.as";
#include "RunnerAnimCommon.as";
#include "RunnerCommon.as";
#include "Knocked.as";
#include "ModPath.as";

void onInit(CSprite@ this) {
	CBlob@ blob = this.getBlob();

	this.RemoveSpriteLayer("background");
	CSpriteLayer@ background = this.addSpriteLayer("background", "JuggernautBackground.png", 64, 64, blob.getTeamNum(), 0);

	if (background !is null) {
		Animation@ anim0 = background.addAnimation("default", 0, false);
		int[] frames0 = {
			0
		};
		anim0.AddFrames(frames0);

		Animation@ anim1 = background.addAnimation("grabbedIdle", 0, false);
		int[] frames1 = {
			32
		};
		anim1.AddFrames(frames1);

		Animation@ anim2 = background.addAnimation("grabbedRun", 4, true);
		int[] frames2 = {
			33,
			34,
			35,
			36
		};
		anim2.AddFrames(frames2);

		Animation@ anim3 = background.addAnimation("grabbedFall", 5, false);
		int[] frames3 = {
			37,
			38,
			39
		};
		anim3.AddFrames(frames3);

		background.SetVisible(true);
		background.SetRelativeZ( - 10.0f);
	}

	this.RemoveSpriteLayer("foreground");

	CSpriteLayer@ foreground = this.addSpriteLayer("foreground", "JuggernautForeground.png", 64, 64, blob.getTeamNum(), 0);

	if (foreground !is null) {
		Animation@ anim0 = foreground.addAnimation("default", 0, false);
		int[] frames0 = {
			0
		};

		anim0.AddFrames(frames0);

		Animation@ anim1 = foreground.addAnimation("charging", 3, false);
		int[] frames1 = {
			0,
			19,
			18,
			17,
			17,
			17,
			17,
			17,
			17,
			16
		};

		anim1.AddFrames(frames1);

		Animation@ anim2 = foreground.addAnimation("chargedAttack", 3, false);

		int[] frames2 = {
			17,
			18,
			19,
			20,
			20,
			20
		};

		anim2.AddFrames(frames2);

		foreground.SetVisible(true);
		foreground.SetRelativeZ(1.0f);
	}

	this.RemoveSpriteLayer("victim");

	CSpriteLayer@ victim = this.addSpriteLayer("victim", "KnightVictim.png", 64, 64, 0, 0);

	if (victim !is null) {
		Animation@ anim0 = victim.addAnimation("default", 0, false);
		int[] frames0 = {
			0
		};

		anim0.AddFrames(frames0);

		Animation@ anim1 = victim.addAnimation("grabbedIdle", 0, false);
		int[] frames1 = {
			32
		};
		
		anim1.AddFrames(frames1);

		Animation@ anim2 = victim.addAnimation("grabbedRun", 4, true);
		int[] frames2 = {
			33,
			34,
			35,
			36
		};

		anim2.AddFrames(frames2);

		Animation@ anim3 = victim.addAnimation("grabbedFall", 5, false);
		int[] frames3 = {
			37,
			38,
			39
		};

		anim3.AddFrames(frames3);

		victim.SetVisible(false);
		victim.SetRelativeZ( - 1.0f);
	}

	blob.set_u16("teamOnSpawn", blob.getTeamNum());
}

void onTick(CSprite@ this) {
	CBlob@ blob = this.getBlob();

	if (blob.get_u16("teamOnSpawn") != blob.getTeamNum()) {
		onInit(this);
	}

	Vec2f pos = blob.getPosition();
	Vec2f aimpos;

	JuggernautInfo@ juggernaut;

	if (!blob.get("JuggernautInfo", @juggernaut)) {
		return;
	}

	const uint8 knocked = getKnocked(blob);

	bool pressed_a1 = blob.isKeyPressed(key_action1);
	bool pressed_a2 = blob.isKeyPressed(key_action2);

	bool walking = (blob.isKeyPressed(key_left) || blob.isKeyPressed(key_right));

	aimpos = blob.getAimPos();
	bool inair = (!blob.isOnGround() && !blob.isOnLadder());

	Vec2f vel = blob.getVelocity();

	CSpriteLayer@ background = this.getSpriteLayer("background");

	if (background is null) {
		return;
	}

	CSpriteLayer@ foreground = this.getSpriteLayer("foreground");

	if (foreground is null) {
		return;
	}

	CSpriteLayer@ victim = this.getSpriteLayer("victim");

	if (victim is null) {
		return;
	}

	if (blob.hasTag("dead")) {
		blob.Untag("attack head");
		blob.Tag("dead head");

		if (this.animation.name != "dead") {
			this.SetAnimation("dead");
		}

		Vec2f oldvel = blob.getOldVelocity();

		//TODO: trigger frame one the first time we server_Die()()
		if (vel.y < -1.0f) {
			this.SetFrameIndex(1);
		} else if (vel.y > 1.0f) {
			this.SetFrameIndex(3);
		} else {
			this.SetFrameIndex(2);
		}

		background.SetVisible(false);
		foreground.SetVisible(false);
		victim.SetVisible(false);

		return;
	}

	// get the angle of aiming with mouse
	Vec2f vec;
	int direction = blob.getAimDirection(vec);

	// set facing
	bool facingLeft = this.isFacingLeft();

	const bool left = blob.isKeyPressed(key_left);
	const bool right = blob.isKeyPressed(key_right);
	const bool up = blob.isKeyPressed(key_up);
	const bool down = blob.isKeyPressed(key_down);

	bool shinydot = false;

	bool grabbed = juggernaut.state == JuggernautStates::Holding;
	victim.SetVisible(grabbed);

	blob.Untag("attack head");
	blob.Untag("dead head");

	if (juggernaut.state != JuggernautStates::Fatality) {
		this.SetOffset(Vec2f());
	}

	if (juggernaut.state == JuggernautStates::Fatality) {
		if (juggernaut.prevState != juggernaut.state) {
			this.SetFacingLeft(false);
		}

		this.SetAnimation(blob.get_string("grabbedEnemy") == "crossbowman" ? "fatalityCrossbowman": "fatality");
		background.SetAnimation("default");
		foreground.SetAnimation("default");
		victim.SetAnimation("default");

		this.SetFacingLeft(false);
		this.SetOffset(Vec2f( - 3.0f, -7.0f));
	} else if (juggernaut.state == JuggernautStates::Stunned || blob.hasTag("seated")) {
		if (juggernaut.state == JuggernautStates::Stunned) {
			blob.Tag("dead head");
		}
		this.SetAnimation("crouch");
		background.SetAnimation("default");
		foreground.SetAnimation("default");
		victim.SetAnimation("default");
	}
	else if (juggernaut.state == JuggernautStates::Charging) {
		blob.Tag("attack head");
		blob.Untag("dead head");

		this.SetAnimation("charging");
		background.SetAnimation("default");
		foreground.SetAnimation("charging");
		victim.SetAnimation("default");
	} else if (juggernaut.state == JuggernautStates::SwingingHammer) {
		blob.Tag("attack head");
		blob.Untag("dead head");

		this.SetFacingLeft(juggernaut.wasFacingLeft);
		this.SetAnimation("chargedAttack");
		background.SetAnimation("default");
		foreground.SetAnimation("chargedAttack");
		victim.SetAnimation("default");
	} else if (juggernaut.state == JuggernautStates::Grabbing) {
		blob.Tag("attack head");
		blob.Untag("dead head");

		f32 angle = juggernaut.attackTrueRot;

		if (angle >= 35.0f && angle <= 145.0f) {
			this.SetAnimation("grabbingUp");
		} else if (angle <= 325.0f && angle >= 215.0f) {
			this.SetAnimation("grabbingDown");
		} else {
			this.SetAnimation("grabbing");
		}

		this.SetFacingLeft(juggernaut.wasFacingLeft);
		background.SetAnimation("default");
		foreground.SetAnimation("default");
		victim.SetAnimation("default");
	} else if (juggernaut.state == JuggernautStates::Throwing) {
		blob.Tag("attack head");
		blob.Untag("dead head");

		f32 angle = juggernaut.attackTrueRot;

		if (angle >= 35.0f && angle <= 145.0f) {
			this.SetAnimation("throwingUp");
		} else if (angle <= 325.0f && angle >= 215.0f) {
			this.SetAnimation("throwingDown");
		} else {
			this.SetAnimation("throwing");
		}

		background.SetAnimation("default");
		foreground.SetAnimation("default");
		victim.SetAnimation("default");
	}
	else if (inair) {
		RunnerMoveVars@ moveVars;

		if (!blob.get("moveVars", @moveVars)) {
			return;
		}

		f32 vy = vel.y;

		if (vy < -0.0f && moveVars.walljumped) {
			this.SetAnimation(grabbed ? "grabbedRun": "run");
			background.SetAnimation(grabbed ? "grabbedRun": "default");
			victim.SetAnimation(grabbed ? "grabbedRun": "default");
		}
		else {
			this.SetAnimation(grabbed ? "grabbedFall": "fall");
			background.SetAnimation(grabbed ? "grabbedFall": "default");
			victim.SetAnimation(grabbed ? "grabbedFall": "default");
			this.animation.timer = 0;

			if (vy < -1.5) {
				this.animation.frame = 0;
			}
			else if (vy > 1.5) {
				this.animation.frame = 2;
			}
			else {
				this.animation.frame = 1;
			}
		}

		foreground.SetAnimation("default");
	}
	else if (walking || (blob.isOnLadder() && (blob.isKeyPressed(key_up) || blob.isKeyPressed(key_down)))) {
		this.SetAnimation(grabbed ? "grabbedRun": "run");
		background.SetAnimation(grabbed ? "grabbedRun": "default");
		foreground.SetAnimation("default");
		victim.SetAnimation(grabbed ? "grabbedRun": "default");
	}
	else if (grabbed) {
		this.SetAnimation("grabbedIdle");
		background.SetAnimation("grabbedIdle");
		foreground.SetAnimation("default");
		victim.SetAnimation("grabbedIdle");
	}
	else {
		defaultIdleAnim(this, blob, direction);
		background.SetAnimation("default");
		foreground.SetAnimation("default");
		victim.SetAnimation("default");
	}

	background.SetFacingLeft(this.isFacingLeft());
	foreground.SetFacingLeft(this.isFacingLeft());
}

void onGib(CSprite@ this) {

}

// render cursors
void DrawCursorAt(Vec2f position, string &in filename) {
	position = getMap().getAlignedWorldPos(position);

	if (position == Vec2f_zero) {
		return;
	}

	position = getDriver().getScreenPosFromWorldPos(position - Vec2f(1, 1));

	GUI::DrawIcon(filename, position, getCamera().targetDistance * getDriver().getResolutionScaleFactor());
}

const string CursorTexture = "Entities/Characters/Sprites/TileCursor.png";

void onRender(CSprite@ this) {
	CBlob@ blob = this.getBlob();

	if (!blob.isMyPlayer()) {
		return;
	}

	if (getHUD().hasButtons()) {
		return;
	}

	// draw tile cursor
	if (blob.isKeyPressed(key_action1)) {
		CMap@ map = blob.getMap();
		Vec2f position = blob.getPosition();
		Vec2f cursor_position = blob.getAimPos();
		Vec2f surface_position;

		map.rayCastSolid(position, cursor_position, surface_position);

		Vec2f vector = surface_position - position;
		f32 distance = vector.getLength();
		Tile tile = map.getTile(surface_position);

		if ((map.isTileSolid(tile) || map.isTileGrass(tile.type)) && map.getSectorAtPosition(surface_position, "no build") is null && distance < 16.0f) {
			DrawCursorAt(surface_position, CursorTexture);
		}
	}
}