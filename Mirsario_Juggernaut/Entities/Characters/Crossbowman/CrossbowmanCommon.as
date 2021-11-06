namespace Crossbowman
{
	enum State
	{
		Ready = 0,
		Firing,
		NeedsReload,
		Reloading,
		Stabbing
	}

	enum ArrowType
	{
		Normal = 0,
		Water,
		Fire,
		Bomb,
		Count
	}
	
	const ::s32 ReadyTime = 11;
	const ::s32 PostFireDelay = 5;
	const ::s32 ReloadTime = 30;

	const ::s32 ShootPeriod = 30;
	const ::s32 ShootPeriod_1 = Crossbowman::ShootPeriod / 3;
	const ::s32 ShootPeriod_2 = 2 * Crossbowman::ShootPeriod / 3;

	const ::s32 FiredTime = 7;
	const ::f32 ShootMaxVelocity = 24.0f;
}

shared class CrossbowmanInfo
{
	s8 stateTime;
	s8 chargeTime;
	u8 state;
	bool hasArrow;
	bool needsReload;
	u8 stabDelay;
	u8 fletchCooldown;
	u8 arrowType;
	bool dontHitMore;
	Vec2f attackDirection;
	f32 attackRotation;
	f32 cachedAngle;

	CrossbowmanInfo()
	{
		dontHitMore = false;
		needsReload = false;
		stateTime = 0;
		chargeTime = 0;
		state = 0;
		hasArrow = false;
		stabDelay = 0;
		fletchCooldown = 0;
		arrowType = ArrowType::normal;
		attackDirection = Vec2f(0, 0);
		attackRotation = 0.0f;
	}
};

const string[] arrowTypeNames = {
	"mat_arrows",
	"mat_waterarrows",
	"mat_firearrows",
	"mat_bombarrows"
};

const string[] arrowNames = {
	"Regular arrows",
	"Water arrows",
	"Fire arrows",
	"Bomb arrow"
};

const string[] arrowIcons = {
	"$Arrow$",
	"$WaterArrow$",
	"$FireArrow$",
	"$BombArrow$"
};

bool hasArrows(CBlob@ this)
{
	CrossbowmanInfo@ crossbowman;
	
	if (!this.get("crossbowmanInfo", @crossbowman)) {
		return false;
	}

	if (crossbowman.arrowType >= 0 && crossbowman.arrowType < arrowTypeNames.length) {
		return this.getBlobCount(arrowTypeNames[crossbowman.arrowType]) > 0;
	}
	
	return false;
}

bool hasArrows(CBlob@ this, u8 arrowType)
{
	return this.getBlobCount(arrowTypeNames[arrowType]) > 0;
}

void SetArrowType(CBlob@ this, const u8 type)
{
	CrossbowmanInfo@ crossbowman;
	
	if (!this.get("crossbowmanInfo", @crossbowman)) {
		return;
	}
	
	crossbowman.arrowType = type;
}

u8 getArrowType(CBlob@ this)
{
	CrossbowmanInfo@ crossbowman;
	
	if (!this.get("crossbowmanInfo", @crossbowman)) {
		return 0;
	}
	
	return crossbowman.arrowType;
}
