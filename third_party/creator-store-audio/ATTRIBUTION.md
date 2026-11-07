# Weapon audio from Roblox Creator Store

SOURCE.json records the asset names, authors, IDs, metadata endpoint and public
free listing status checked during integration. Asset pages use
`https://create.roblox.com/store/asset/<ID>`. Use is subject to Creator Store
terms inside Roblox. No audio binaries are redistributed in this repository.

The old eight kit sounds were returned as unpublished and not free by that
endpoint. Preserve the original kit archives; only the derived Arsenal.rbxmx
references are replaced. Meshes, textures, joints and animation attribution
remain in third_party/roblox-weapon-kit/.

Public listing is not a playback test. Anonymous asset delivery returned HTTP
401, including for public candidates; experience playback must be verified in
Roblox Studio. No claim is made that those endpoints authorized this experience.
