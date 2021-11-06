
#include "HittersNew.as";
#include "Knocked.as"

void onInit(CBlob@ this)
{
	this.getCurrentScript().removeIfTag = "dead";
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (blob is null)   // map collision?
	{
		return;
	}

	if (!solid)
	{
		return;
	}

	// server only
	if (!getNet().isServer() || !blob.hasTag("player")) { return; }

	if (this.getPosition().y < blob.getPosition().y - 2)
	{
		float enemydam = 0.0f;
		f32 vely = this.getOldVelocity().y;

		if (vely > 10.0f)
		{
			enemydam = 2.0f;
		}
		else if (vely > 5.5f)
		{
			enemydam = 1.0f;
		}
		
		// 2x damage because ur a juggernaut!
		enemydam *= 2.0f;

		if (enemydam > 0)
		{
			this.server_Hit(blob, this.getPosition(), Vec2f(0, 1) , enemydam, HittersNew::stomp);
		}
	}
}

// effects

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (customData == HittersNew::stomp && damage > 0.0f && velocity.y > 0.0f && worldPoint.y < this.getPosition().y)
	{
		this.getSprite().PlaySound("Entities/Characters/Sounds/Stomp.ogg");
		SetKnocked(this, 15);
	}
	
	return damage;
}
