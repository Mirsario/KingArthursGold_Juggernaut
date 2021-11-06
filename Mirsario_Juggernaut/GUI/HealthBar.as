// draws a health bar on mouse hover

void onRender(CSprite@ this)
{
	if (g_videorecording)
		return;
	
	CBlob@ blob = this.getBlob();
	if(blob.isMyPlayer()){
		return;
	}

	Vec2f center = blob.getPosition();
	Vec2f mouseWorld = getControls().getMouseWorldPos();
	const f32 renderRadius = (blob.getRadius()) * 0.95f;
	bool mouseOnBlob = (mouseWorld - center).getLength() < renderRadius;
	if (mouseOnBlob || blob.getConfig()=="juggernaut")
	{
		//VV right here VV
		Vec2f pos2d = blob.getScreenPos() - Vec2f(0,2);
		Vec2f dim = Vec2f(32, 12);
		const f32 y = blob.getHeight() * 2.4f;
		f32 initialHealth = blob.getInitialHealth();
		if(blob.getConfig()=="juggernaut") {
			initialHealth=	blob.get_f32("realInitialHealth");
		}
		if (initialHealth > 0.0f)
		{
			const f32 perc = blob.getHealth() / initialHealth;
			if (perc >= 0.0f)
			{
				Vec2f center=	(Vec2f(pos2d.x-dim.x,pos2d.y+y)+Vec2f(pos2d.x+dim.x,pos2d.y+y+dim.y))*0.5f;
				GUI::DrawRectangle(Vec2f(pos2d.x - dim.x - 2, pos2d.y + y - 2), Vec2f(pos2d.x + dim.x + 2, pos2d.y + y + dim.y + 2));
				GUI::DrawRectangle(Vec2f(pos2d.x - dim.x + 2, pos2d.y + y + 2), Vec2f(pos2d.x - dim.x + perc * 2.0f * dim.x - 2, pos2d.y + y + dim.y - 2), SColor(0xffac1512));
				GUI::DrawTextCentered(formatFloat(blob.getHealth()*2.0f,'0',3,1)+" Hearts",center+Vec2f(0.0f,-2.0f),SColor(255,255,255,255));
			}
		}
	}
}