namespace Juggernaut
{
	interface IBlobState
	{
		void OnActivate(CBlob@ this);
		void UpdateLogic(CBlob@ this);
		void UpdateSprite(CSprite@ this);
	}
}