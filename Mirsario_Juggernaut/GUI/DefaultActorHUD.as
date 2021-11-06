//default actor hud
// a bar with hearts in the bottom left, bottom right free for actor specific stuff

#include "ActorHUDStartPos.as";

void renderBackBar(Vec2f origin, f32 width, f32 scale)
{
	for (f32 step = 0.0f; step < width / scale - 64; step += 64.0f * scale)
	{
		GUI::DrawIcon("Entities/Common/GUI/BaseGUI.png", 1, Vec2f(64, 32), origin + Vec2f(step * scale, 0), scale);
	}

	GUI::DrawIcon("Entities/Common/GUI/BaseGUI.png", 1, Vec2f(64, 32), origin + Vec2f(width - 128 * scale, 0), scale);
}

void renderFrontStone(Vec2f farside, f32 width, f32 scale)
{
	for (f32 step = 0.0f; step < width / scale - 16.0f * scale * 2; step += 16.0f * scale * 2)
	{
		GUI::DrawIcon("Entities/Common/GUI/BaseGUI.png", 2, Vec2f(16, 32), farside + Vec2f(-step * scale - 32 * scale, 0), scale);
	}

	if (width > 16)
	{
		GUI::DrawIcon("Entities/Common/GUI/BaseGUI.png", 2, Vec2f(16, 32), farside + Vec2f(-width, 0), scale);
	}

	GUI::DrawIcon("Entities/Common/GUI/BaseGUI.png", 0, Vec2f(16, 32), farside + Vec2f(-width - 32 * scale, 0), scale);
	GUI::DrawIcon("Entities/Common/GUI/BaseGUI.png", 3, Vec2f(16, 32), farside, scale);
}

void renderHPBar(CBlob@ blob, Vec2f origin)
{
	string heartFile = "GUI/HeartNBubble.png";
	int segmentWidth = 32;
	GUI::DrawIcon("Entities/Common/GUI/BaseGUI.png", 0, Vec2f(16, 32), origin + Vec2f(-segmentWidth, 0));
	int HPs = 0;

	for (f32 step = 0.0f; step < blob.getInitialHealth(); step += 0.5f)
	{
		GUI::DrawIcon("Entities/Common/GUI/BaseGUI.png", 1, Vec2f(16, 32), origin + Vec2f(segmentWidth * HPs, 0));
		f32 thisHP = blob.getHealth() - step;

		if (thisHP > 0)
		{
			Vec2f heartoffset = (Vec2f(2, 10) * 2);
			Vec2f heartpos = origin + Vec2f(segmentWidth * HPs, 0) + heartoffset;

			if (thisHP <= 0.125f)
			{
				GUI::DrawIcon(heartFile, 4, Vec2f(12, 12), heartpos);
			}
			else if (thisHP <= 0.25f)
			{
				GUI::DrawIcon(heartFile, 3, Vec2f(12, 12), heartpos);
			}
			else if (thisHP <= 0.375f)
			{
				GUI::DrawIcon(heartFile, 2, Vec2f(12, 12), heartpos);
			}
			else
			{
				GUI::DrawIcon(heartFile, 1, Vec2f(12, 12), heartpos);
			}
		}

		HPs++;
	}

	GUI::DrawIcon("Entities/Common/GUI/BaseGUI.png", 3, Vec2f(16, 32), origin + Vec2f(32 * HPs, 0));
}

void renderJuggernautHPBar(CBlob@ blob, Vec2f origin)
{
	f32 initialHealth=	blob.get_f32("realInitialHealth");	//blob.getInitialHealth();

	if (initialHealth > 0.0f)
	{
		f32 backoffset = 64;

		GUI::DrawIcon("Entities/Common/GUI/BaseGUI.png", 0, Vec2f(16, 32), origin + Vec2f(-224 + backoffset, 0));
		GUI::DrawIcon("Entities/Common/GUI/BaseGUI.png", 2, Vec2f(16, 32), origin + Vec2f(-192 + backoffset, 0));
		GUI::DrawIcon("Entities/Common/GUI/BaseGUI.png", 2, Vec2f(16, 32), origin + Vec2f(-160 + backoffset, 0));
		GUI::DrawIcon("Entities/Common/GUI/BaseGUI.png", 2, Vec2f(16, 32), origin + Vec2f(-128 + backoffset, 0));
		GUI::DrawIcon("Entities/Common/GUI/BaseGUI.png", 2, Vec2f(16, 32), origin + Vec2f(-96 + backoffset, 0));
		GUI::DrawIcon("Entities/Common/GUI/BaseGUI.png", 2, Vec2f(16, 32), origin + Vec2f(-64 + backoffset, 0));
		GUI::DrawIcon("Entities/Common/GUI/BaseGUI.png", 2, Vec2f(16, 32), origin + Vec2f(-32 + backoffset, 0));
		GUI::DrawIcon("Entities/Common/GUI/BaseGUI.png", 3, Vec2f(16, 32), origin + Vec2f(0 + backoffset, 0));

		// Health
		f32 hpPercent = blob.getHealth() / initialHealth;
		Vec2f hpSize = Vec2f(192, 19);
		Vec2f hpOffset = Vec2f(-128,16);

		GUI::DrawRectangle(Vec2f(hpOffset.x + origin.x, hpOffset.y + origin.y), Vec2f(hpOffset.x + origin.x + hpSize.x, hpOffset.y + origin.y + hpSize.y));

		if (hpPercent >= 0.0f)
		{
			GUI::DrawRectangle(Vec2f(hpOffset.x + origin.x + 4, hpOffset.y + origin.y + 4), Vec2f(hpOffset.x + origin.x + (hpSize.x * hpPercent) - 4, hpOffset.y + origin.y + hpSize.y - 4), SColor(0xffb73333));
		}
		GUI::DrawTextCentered(formatFloat(blob.getHealth()*2.0f,'0',3,1)+" Hearts",origin+hpOffset+(hpSize/2),SColor(255,255,255,255));
	}
}

void onInit(CSprite@ this)
{
	this.getCurrentScript().runFlags |= Script::tick_myplayer;
	this.getCurrentScript().removeIfTag = "dead";
}

void onRender(CSprite@ this)
{
	if (g_videorecording)
		return;

	CBlob@ blob = this.getBlob();
	Vec2f dim = Vec2f(362, 64);
	Vec2f ul(HUD_X - dim.x / 2.0f, HUD_Y - dim.y + 12);
	Vec2f lr(ul.x + dim.x, ul.y + dim.y);
	//GUI::DrawPane(ul, lr);
	renderBackBar(ul, dim.x, 1.0f);
	u8 bar_width_in_slots = blob.get_u8("gui_HUD_slots_width");
	f32 width = bar_width_in_slots * 32.0f;
	renderFrontStone(ul + Vec2f(dim.x + 32, 0), width, 1.0f);
	if(blob.getName() != "juggernaut")
		renderHPBar(blob, ul);
	else
		renderJuggernautHPBar(blob, ul);
	//GUI::DrawIcon("Entities/Common/GUI/BaseGUI.png", 0, Vec2f(128,32), topLeft);
}
