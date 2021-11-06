#include "Hitters.as";

void onInit(CBlob@ this)
{
	this.getShape().SetGravityScale(0.4f);
	this.server_SetTimeToDie(1 + XORRandom(2));
	
	this.getCurrentScript().tickFrequency = 2;
	
	this.SetLight(true);
	this.SetLightRadius(48.0f);
	this.SetLightColor(SColor(255, 255, 200, 50));
}

void onTick(CBlob@ this)
{
	if (getNet().isServer() && this.getTickSinceCreated() > 5) getMap().server_setFireWorldspace(this.getPosition() + Vec2f(XORRandom(16) - 8, XORRandom(16) - 8), true);
}

void onTick(CSprite@ this)
{
	if (!getNet().isClient()) return;

	ParticleAnimated(CFileMatcher("SmallFire").getFirst(), this.getBlob().getPosition() + Vec2f(XORRandom(16) - 8, XORRandom(16) - 8), Vec2f(0, 0), 0, 1.0f, 2, 0.25f, false);
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (this.get_u32("next collision time") > getGameTime()) return;

	if (solid) 
	{
		if (getNet().isServer())
		{
			getMap().server_setFireWorldspace(this.getPosition(), true);
			// this.server_Die();
		}
	}
	else if (blob !is null && blob.isCollidable())
	{
		if (getNet().isServer())
		{
			// if (this.getTickSinceCreated() > 3) this.server_Hit(blob, this.getPosition(), Vec2f(0, 0), 0.50f, Hitters::fire, false);
			if (this.getTeamNum() != blob.getTeamNum()) this.server_Hit(blob, this.getPosition(), Vec2f(0, 0), 0.50f, Hitters::fire, false);
		}
	}
	
	this.set_u32("next collision time", getGameTime() + 2);
}