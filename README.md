### User-friendly and simple API to create, play and control taunts, dances and any other player sequences.
By default addon does not contain animations from Custom Taunt, you can install them individually, check out this collection: [uTaunt](https://steamcommunity.com/workshop/filedetails/?id=3161525439)

## Features
- **High Performance** - addon has a very low hardware requirements.
- **Simple** - users have access to one small menu with all sequences.
- **Extensibility** - other developers can expand the list of available sequences.
- **Reliable** - all sequences are synchronized both on server and client, implemented work with network and PVS.
- **Co-op Dances** - addon supports creating co-dances, as an example we have 2 dances from MMD ( Custom Taunt ).
- **Support** - addon will receive all necessary patches and updates during the year.
- **Modifiable** - addon lets you replace its menu and individual playback control by other scripts.

## Where is Lua code?
Written in [Yuescript](https://github.com/pigpigyyy/Yuescript), compiled Lua code can be found in [releases](https://github.com/PrikolMen/unknown-taunts/releases) and [lua branch](https://github.com/PrikolMen/unknown-taunts/tree/lua), or you can compile it yourself using compiled [Yuescript Compiler](https://github.com/pigpigyyy/Yuescript/releases/latest).

## Docs

### Server Functions
- `boolean` uTaunt.Start( `Player` ply, `string` sequenceName, `boolean` force, `float` cycle, `Vector` startOrigin, `Angle` startAngles ) - returns **true** if successful, otherwise **false**.
- `boolean` uTaunt.Join( `Player` ply, `Player` dancingPlayer ) - returns **true** if successful, otherwise **false**.
- `boolean` uTaunt.Finish( `Player` ply ) - returns **true** if successful, otherwise **false**.
- `string` - uTaunt.SetSequenceName( `Player` ply, `string` sequenceName ) - sets sequence name as **string**.
- `boolean` uTaunt.SetCycle( `Player` ply, `int` sequenceID, `float` cycle ) - sets sequence progress from 0 to 1 as **float**, returns **true** if successful, otherwise **false**.
- uTaunt.SetRenderAngles( `Player` ply, `Angle` angles ) - sets angles of player render as **Angle**.
- uTaunt.IsAudioEnabled( `Player` ply ) - returns **true** if sequences audio is enabled.
- uTaunt.IsCoopEnabled( `Player` ply ) - returns **true** if sequences in co-op mode is enabled.

### Shared Functions
- `table` uTaunt.FindSequences( `Entity` entity, `string` pattern ) - returns list with sequences data like `{ id = 0, name = "idle", duration = 1 }`.
- `boolean` uTaunt.IsValidTauntingPlayer( `Entity` entity ) - returns **true** if entity is a valid and alive player that using uTaunt ( taunt at this time ).
- `boolean` uTaunt.IsPlayingTaunt( `Player` ply ) - returns **true** if player is using uTaunt ( taunt at this time ).
- `string` uTaunt.GetSequenceName( `Player` ply ) - returns current sequence name as **string**.
- `double` uTaunt.GetStartTime( `Player` ply ) - returns start time point in CurTime as **double**.
- `float` uTaunt.GetCycle( `Player` ply, `int` sequenceID, `double` startTime ) - retuns sequence progress from 0 to 1 as **float**.
- `Angle` uTaunt.GetRenderAngles( `Player` ply ) - returns player render angles as **Angle**.

### Client Functions
- `boolean` IsInTaunt() - returns **true** if local player is taunting.
- uTaunt.ToggleMenu( `Player` ply ) - toggles uTaunt menu.
- `string` uTaunt.GetPhrase( `string` placeholder ) - returns localized phrase as **string**.
- `boolean` uTaunt.IsAudioEnabled() - returns **true** if sequences audio is enabled.
- `boolean` uTaunt.IsCoopEnabled() - returns **true** if coop sequences is allowed.

### Shared Hooks
- GM:TauntStartCommand( `Player` ply, `CUserCommand` cmd, `string` sequenceName ) - called when player taunting, here can be returned the bit number of buttons that the player presses.
- GM:UnknownTauntSound( `Player` ply, `string` sequenceName, `float` cycle, `double` duration, `int` sequenceID ) - called when player starts dancing, if **string** is returned here then sound will be used on string as sound path, if **false** then sound will be blocked, if **true** or **nil** then default action. Also accepts links to web audio files and online radio stations.
- GM:PlayerTauntThink( `Player` ply, `boolean` isUTaunt ) - called while player is taunting.

### Server Hooks
- GM:PlayerStartedUnknownTaunt( `Player` ply, `string` sequenceName, `double` duration ) - called when a player's taunt was started.
- GM:PlayerFinishedTaunt( `Player` ply, `string` sequenceName, `boolean` isFinished, `double` timeRemaining, `int` sequenceID, `double` finishTime ) - called when a player's taunt was stopped.
- GM:PlayerShouldUnknownTaunt( `Player` ply, `int` sequenceID ) - if **false** is returned here, taunt will be blocked, if **true** then allowed.
- GM:PlayerShouldFinishTaunt( `Player` ply, `string` sequenceName, `boolean` isFinished, `double` timeRemaining, `int` sequenceID, `double` finishTime ) - if return here **false** taunt won't be stopped ( personally, I don't recommend using this, but if you need... ).
- GM:UnknownTauntThink( `Player` ply, `string` sequenceName, `float` cycle, `int` sequenceID ) - called while a player is taunting, if **false** is returned here, taunt will be stopped.
- GM:PlayerShouldCoopTaunt( `Player` ply, `Player` otherPlayer, `string` sequenceName ) - if **false** is returned here, then cooperative dancing will be forbidden, if **true** it will be allowed.

### Client Hooks
- GM:AllowTauntMenu( `Player` ply ) - if **false** is returned here then taunt menu opening will be blocked.
- GM:UnknownTauntMenuSetup( `Player` ply, `function` add ) - called when taunt menu is being created, with '**add**' you can add more taunts and categories to that menu `add( "title", sequenceNamesList )`.
- GM:AllowUnknownTaunt( `Player` ply, `string` sequenceName, `string` categoryTitle ) - taunt filter for a player, if **false** is returned here, taunt will be hidden in the taunt menu.
- GM:UnknownTauntSynced( `Player` ply, `string` sequenceName, `float` cycle, `int` sequenceID, `boolean` isWebAudio ) - called when player taunt is being synced.
- GM:PlayerFinishedTaunt( `Player` ply, `string` sequenceName ) - called when player is finished taunt.
