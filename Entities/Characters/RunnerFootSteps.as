#define CLIENT_ONLY

#include "RunnerCommon.as"

void onInit(CSprite@ this)
{
	this.getCurrentScript().runFlags |= Script::tick_onground;
	this.getCurrentScript().runFlags |= Script::tick_not_inwater;
	this.getCurrentScript().runFlags |= Script::tick_moving;
	this.getCurrentScript().removeIfTag = "dead";
}

void onTick(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	if (/*blob.isOnGround() && */(blob.isKeyPressed(key_left) || blob.isKeyPressed(key_right)))
	{
		RunnerMoveVars@ moveVars;
		if (!blob.get("moveVars", @moveVars))
		{
			return;
		}
		if ((blob.getNetworkID() + getGameTime()) % (moveVars.walkFactor < 1.0f ? 14 : 8) == 0)
		{
			f32 volume = Maths::Min(0.1f + Maths::Abs(blob.getVelocity().x) * 0.1f, 1.0f);
			TileType tile = blob.getMap().getTile(blob.getPosition() + Vec2f(0.0f, blob.getRadius() + 4.0f)).type;

			f32 pitch = 1.0f;
			if(blob.getConfig() == "juggernaut")
			{
				volume *= 2.0f;
				pitch = 0.75f;
			}

			if (blob.getMap().isTileGroundStuff(tile))
			{
				this.PlayRandomSound("/EarthStep", volume, pitch);
			}
			else
			{
				this.PlayRandomSound("/StoneStep", volume, pitch);
			}
		}
	}
}
