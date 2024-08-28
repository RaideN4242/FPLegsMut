Class FPLegsMut extends Mutator;

function PostBeginPlay()
{
	local DZ_GameType KF;

	KF = DZ_GameType(Level.Game);

	if (KF == none) 
	{
		Log("ERROR: Wrong GameType (requires DZ_GameType)", Class.Outer.Name);
		Destroy();
		return;
	}
	
	if ( !ClassIsChildOf(KF.PlayerControllerClass, class'ServerPerksDZ.FPPlayerController') ) 
	{
		KF.PlayerControllerClass = class'ServerPerksDZ.FPPlayerController';
		KF.PlayerControllerClassName = string(Class'ServerPerksDZ.FPPlayerController');
	}
}

defaultproperties
{
     bAddToServerPackages=True
     GroupName="KF-FPLegs"
     FriendlyName="FP=Legs Base Mut"
     Description="Adds a nice pair of FPLegs"
}
