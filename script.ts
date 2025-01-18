import { rm } from './deps.ts'
import * as bundleInfo from './bundleinfo.json' with { type: 'json' }

const pipeline = await rm.createPipeline({
    bundleInfo,
})
const info = pipeline.infoAsV2

// ----------- { SCRIPT } -----------

/*
This script was created on ReMapper V3, and later ported to V4.
I realized that having an example for launch would be ideal.
*/

const bundle = rm.loadBundle(bundleInfo)
const materials = bundle.materials
const prefabs = bundle.prefabs

const TIMES = {
    // forcing sorting order in intellisense
    _0_INTRO: 0,
    _1_AMBIENT: 34,
    _2_AMBIENT_RISE: 70,
    _3_BUILDUP: 98,
    _4_DROP: 112.5,
    _5_OUTRO: 140.75,
    _6_TEXT: 172.75,
} as const // this provides the value in the type instead of "number"

async function doMap(diffName: rm.DIFFICULTY_NAME) {
    const map = await rm.readDifficultyV3(pipeline, diffName)

    //#region Environment

    // Clear space
    rm.getBaseEnvironment(map, (x) => {
        x.position = [0, -69420, 0]
        x.components ??= {}
        x.components.BloomFogEnvironment = {
            attenuation: 0,
        }
    })
    //#endregion

    //#region Notemods

    // Seeded random
    // This is a thing in RM4 but I don't wanna fuck with it so this implementation remains
    function mulberry32(a: number) {
        return function (min: number, max: number) {
            let t = a += 0x6D2B79F5
            t = Math.imul(t ^ t >>> 15, t | 1)
            t ^= t + Math.imul(t ^ t >>> 7, t | 61)
            const r = ((t ^ t >>> 14) >>> 0) / 4294967296
            return rm.lerp(min, max, r)
        }
    }

    // Setup notes
    map.allNotes.forEach((x) => {
        if (!(x instanceof rm.Arc)) {
            x.disableSpawnEffect = true
        }

        x.track.add('noteChild')
    })

    // Parent to player
    rm.assignTrackParent(map, 0, ['noteChild'], 'player')
    rm.assignPlayerToTrack(map, 0, 'player')

    // Intro notes
    rm.assignObjectPrefab(map, {
        colorNotes: {
            track: 'introNote',
            asset: prefabs.reflectivenote.path,
            debrisAsset: prefabs.reflectivenote_debris.path,
        },
    })

    map.allNotes.forEach((x) => {
        if (
            x.beat >= 0 && x.beat <= 33
        ) {
            x.disableNoteGravity = true
            x.noteJumpOffset = 4
            x.track.add('introNote')

            const rand = mulberry32(x.beat * 10)

            x.animation.offsetWorldRotation = [[
                rand(-10, 10),
                rand(-10, 10),
                rand(-10, 10),
                0,
            ], [0, 0, 0, 0.45, 'easeOutSine']]

            x.animation.localRotation = [[
                rand(-180, 180),
                rand(-180, 180),
                rand(-180, 180),
                0,
            ], [0, 0, 0, 0.45, 'easeOutSine']]
        }
    })

    // Ambient
    rm.assignObjectPrefab(map, {
        colorNotes: {
            track: 'ambientNote',
            asset: prefabs.glassnote.path,
            debrisAsset: prefabs.glassnote_debris.path,
        },
        chainHeads: {
            track: 'ambientNote',
            asset: prefabs.glassnotechain.path,
            debrisAsset: prefabs.glassnotechain_debris.path,
        },
        chainLinks: {
            track: 'ambientNote',
            asset: prefabs.glassnotechainlink.path,
            debrisAsset: prefabs.glassnotechainlink_debris.path,
        },
    })

    rm.assignPathAnimation(map, {
        track: 'ambientNote',
        animation: {
            offsetPosition: [
                [0, 0, 700, 0],
                [0, 0, 0, 0.455, 'easeOutCirc'],
            ],
        },
    })

    rm.assignPathAnimation(map, {
        beat: 34,
        duration: 4,
        track: 'ambientNote',
        animation: {
            offsetPosition: [0, 0, 0],
        },
        easing: 'easeInOutExpo',
    })

    map.allNotes.forEach((x) => {
        if (
            x.beat >= 33 && x.beat <= 98.5
        ) {
            x.disableNoteGravity = true
            x.noteJumpOffset = 4
            x.track.add('ambientNote')

            const rand = mulberry32(x.beat * 10)

            let scalar = Math.sin(x.beat * 0.3) * 0.5 + 0.5

            const movement = (x.beat - TIMES._2_AMBIENT_RISE) /
                (TIMES._3_BUILDUP - TIMES._2_AMBIENT_RISE)

            if (movement > 0) {
                const fraction = Math.pow(1 - movement, 2)
                scalar *= rm.lerp(0.5, 1, fraction)
            }

            x.worldRotation = [
                Math.cos(x.beat * 0.2 * 4) * 20 * scalar, // Up and down
                Math.sin(x.beat * 0.1 * 4) * 30 * scalar, // Side to side
                0,
            ]

            x.animation.offsetWorldRotation = [[
                rand(-10, 10),
                rand(-10, 10),
                rand(-10, 10),
                0,
            ], [0, 0, 0, 0.45, 'easeOutSine']]

            x.animation.localRotation = [[
                rand(-180, 180),
                rand(-180, 180),
                rand(-180, 180),
                0,
            ], [0, 0, 0, 0.48, 'easeOutSine']]

            if (x.beat >= 33 && x.beat <= 34.5) {
                x.animation.offsetPosition = [
                    [0, 40, -100, 0],
                    [0, 0, 0, 0.45, 'easeOutSine'],
                ]
                x.animation.offsetWorldRotation = [
                    [0, 0, -40, 0],
                    [0, 0, 0, 0.49, 'easeInOutSine'],
                ]
            }
        }
    })

    const headTrack = 'head'

    rm.assignPlayerToTrack(map, {
        track: headTrack,
        target: 'Head',
    })

    materials.saberguide.set(
        map,
        {
            _EyePosition: ['baseHeadPosition', 0],
        },
        0,
        99999,
    )

    function homogenousPointsVec3ToVec4(points: rm.RawPointsVec3): rm.RawPointsVec4 {
        const complexVec3 = rm.complexifyPoints(points)
        const complexVec4: rm.ComplexPointsVec4 = []

        complexVec3.forEach((point) => {
            const leftover = point.slice(3) as [number, rm.PointFlag]
            complexVec4.push([point[0], point[1], point[2], 0, ...leftover])
        })

        return rm.simplifyPoints(complexVec4)
    }

    function commenceOutOfBodyExperience(position: rm.RawPointsVec3, beat: number, duration?: number) {
        rm.animateTrack(map, {
            track: headTrack,
            beat,
            duration,
            animation: {
                position,
            },
        })

        materials.saberguide.set(
            map,
            {
                _VirtualOffset: homogenousPointsVec3ToVec4(position),
            },
            beat,
            duration,
        )
    }

    materials.saberguide.set(map, {
        _GuideOpacity: 0,
        _GuideSteepness: 0,
    })

    {
        const headStartMovingBeat = TIMES._2_AMBIENT_RISE
        const duration = TIMES._3_BUILDUP - headStartMovingBeat

        commenceOutOfBodyExperience(
            [
                [0, 0, 0, 0],
                [0, 0.8, -4, 0.86, 'easeInOutQuart'],
                [0, 0, 0, 1, 'easeInOutQuart'],
            ],
            headStartMovingBeat,
            duration,
        )

        materials.saberguide.set(
            map,
            {
                _GuideOpacity: [
                    [0, 0],
                    [1, 1, 'easeInOutQuart'],
                ],
                _GuideSteepness: [
                    [0, 0],
                    [materials.saberguide.defaults._GuideSteepness, 1, 'easeInOutQuart'],
                ],
            },
            headStartMovingBeat,
            20,
        )

        materials.saberguide.set(
            map,
            {
                _GuideOpacity: [
                    [1, 0],
                    [0, 1],
                ],
                _GuideSteepness: [
                    [materials.saberguide.defaults._GuideSteepness, 0],
                    [0, 1],
                ],
            },
            TIMES._3_BUILDUP - 8,
            8 - 1,
        )
    }

    // Drop
    const DROP_DUR = TIMES._5_OUTRO - TIMES._4_DROP

    rm.assignObjectPrefab(map, {
        colorNotes: {
            track: 'dropNote',
            asset: prefabs.portalnote.path,
            debrisAsset: prefabs.portalnote_debris.path,
        },
    })

    rm.assignPathAnimation(map, {
        beat: TIMES._1_AMBIENT - 1,
        track: 'dropNote',
        duration: 2,
        animation: {
            dissolve: [[1, 0], [0, 0.1]],
        },
        easing: 'easeInOutCirc',
    })

    rm.assignPathAnimation(map, {
        track: 'dropHitNote',
        animation: {
            scale: [0, 0, 0],
        },
    })

    rm.assignPathAnimation(map, {
        track: 'dropHitNote',
        beat: 107,
        duration: TIMES._4_DROP - 107,
        easing: 'easeInOutExpo',
        animation: {
            scale: [1, 1, 1],
        },
    })

    rm.assignPathAnimation(map, {
        track: 'dropHitNote',
        beat: 111.25,
        animation: {
            scale: [0, 0, 0],
        },
    })

    rm.assignPathAnimation(map, {
        track: 'dropHitNote',
        beat: TIMES._4_DROP,
        animation: {
            scale: [1, 1, 1],
        },
    })

    function cutDirectionAngle(cut: rm.NoteCut) {
        switch (cut) {
            case rm.NoteCut.UP:
                return 180
            case rm.NoteCut.DOWN:
                return 0
            case rm.NoteCut.LEFT:
                return -90
            case rm.NoteCut.RIGHT:
                return 90
            case rm.NoteCut.UP_LEFT:
                return -135
            case rm.NoteCut.UP_RIGHT:
                return 135
            case rm.NoteCut.DOWN_LEFT:
                return -45
            case rm.NoteCut.DOWN_RIGHT:
                return 45
            case rm.NoteCut.DOT:
                return 0
        }
    }

    map.allNotes.forEach((x, i) => {
        if (
            x.beat >= TIMES._4_DROP && x.beat <= TIMES._5_OUTRO
        ) {
            x.track.add('dropNote')
            x.noteJumpOffset = 1.5
            x.noteJumpSpeed = 15

            if (x.beat > TIMES._4_DROP + 1) {
                doDropNoteMods(x, i)
            } else {
                x.animation.dissolve = [[0.8, 0], [0.2, 0.6, 'easeInOutExpo']]
                x.animation.offsetWorldRotation = [
                    [8 + 8 * (x.x - 1), 3 + 8 * (x.x - 0.5), -5 - 20 * x.x, 0],
                    [0, 0, 0, 0.45, 'easeInOutSine'],
                ]
            }
        }
    })

    function doDropNoteMods(note: rm.AnyNote, index: number) {
        note.track.add('dropHitNote')
        note.noteJumpOffset = 5

        const rand = mulberry32(note.beat + 6942)

        const track1 = 'dropPath1_' + index
        const track2 = 'dropPath2_' + index
        note.track.add([track1, track2])

        // initialization
        rm.assignPathAnimation(map, {
            track: track2,
            animation: {
                offsetWorldRotation: [
                    [rand(-20, 20), rand(-20, 20), rand(-20, 20), 0],
                    [0, 0, 0, 0.6],
                ],
                localRotation: [
                    [rand(-120, 120), rand(-120, 120), rand(-120, 120), 0],
                    [0, 0, 0, 0.53],
                ],
                dissolve: [[0, 0], [1, 0.35, 'easeInOutCubic']],
                dissolveArrow: [[1, 0.35], [0, 0.55, 'easeInOutQuart']],
            },
        })

        let lastDir = -1
        for (let t = TIMES._4_DROP; t <= note.beat && t < TIMES._5_OUTRO - 0.5; t += 1.75) {
            const nextNote = map.colorNotes.find(
                (n) => (n.beat >= t && n.cutDirection != lastDir),
            )!
            lastDir = nextNote.cutDirection
            const nextDir = cutDirectionAngle(nextNote.cutDirection)
            const scalar = rand(10, 15)
            const deltaX = Math.cos(rm.toRadians(nextDir)) * scalar
            const deltaY = Math.sin(rm.toRadians(nextDir)) * scalar

            rm.assignPathAnimation(map, {
                track: track1,
                beat: t - 1.75 / 2,
                duration: 1.75,
                easing: 'easeInOutCubic',
                animation: {
                    offsetWorldRotation: [
                        [deltaX, deltaY, rand(-45, 45), 0],
                        [deltaX * 0.3, deltaY * 0.3, 0, 0.5],
                    ],
                    dissolve: [[0, 0], [1, 0.35, 'easeInOutCubic']],
                    dissolveArrow: [[0, 0.37], [1, 0.42, 'easeOutBounce']],
                },
            })

            const randRange = 30
            const randRot = () => rand(-randRange, randRange)
            rm.assignPathAnimation(map, {
                track: track2,
                beat: t,
                duration: 2.4,
                easing: 'easeOutBack',
                animation: {
                    offsetWorldRotation: [
                        [randRot(), randRot(), randRot(), 0],
                        [0, 0, 0, 0.55, 'easeInOutSine'],
                    ],
                    localRotation: [
                        [rand(-45, 45) + 5 * t, rand(-45, 45) + 5 * t, rand(-45, 45) + 5 * t, 0],
                        [0, 0, 0, 0.55, 'easeInOutSine'],
                    ],
                },
            })
        }
    }

    // Outro
    rm.assignObjectPrefab(map, {
        colorNotes: {
            track: 'outroNote',
            asset: prefabs.glassnote.path,
            debrisAsset: prefabs.glassnote_debris.path,
        },
        chainHeads: {
            track: 'outroNote',
            asset: prefabs.glassnotechain.path,
            debrisAsset: prefabs.glassnotechain_debris.path,
        },
        chainLinks: {
            track: 'outroNote',
            asset: prefabs.glassnotechainlink.path,
            debrisAsset: prefabs.glassnotechainlink_debris.path,
        },
    })

    map.allNotes.forEach((x) => {
        if (x.beat >= 141) {
            x.track.add('outroNote')
            x.disableNoteGravity = true
            x.noteJumpOffset = 4
            x.animation.dissolve = [0]

            const rand = mulberry32(x.beat * 10)

            const scalar = Math.sin(x.beat * 0.5) * 0.5 + 0.5

            x.worldRotation = [
                Math.cos(x.beat * 0.2 * 8) * 2 * scalar, // Up and down
                Math.sin(x.beat * 0.1 * 8) * 30 * scalar, // Side to side
                0,
            ]

            x.animation.offsetWorldRotation = [[
                rand(-10, 10),
                rand(-10, 10),
                rand(-10, 10),
                0,
            ], [0, 0, 0, 0.45, 'easeOutSine']]

            x.animation.localRotation = [[
                rand(-180, 180),
                rand(-180, 180),
                rand(-180, 180),
                0,
            ], [0, 0, 0, 0.45, 'easeOutSine']]
        }
    })

    // Trailer Cameras
    function insertTrailerCamera(beat: number, prefab: rm.Prefab) {
        const note = map.colorNotes.find((x) => x.beat > beat)
        if (!note) return

        const track = prefab.name
        note.track.add(track)
        rm.assignObjectPrefab(map, {
            loadMode: 'Additive',
            colorNotes: {
                track,
                asset: prefab.path,
            },
        })
    }

    insertTrailerCamera(TIMES._0_INTRO + 14, prefabs.trailercamera_1)
    insertTrailerCamera(TIMES._1_AMBIENT + 18, prefabs.trailercamera_2)
    insertTrailerCamera(TIMES._2_AMBIENT_RISE + 20, prefabs.trailercamera_3)
    insertTrailerCamera(TIMES._4_DROP + 10, prefabs.trailercamera_4)
    insertTrailerCamera(TIMES._5_OUTRO + 10, prefabs.trailercamera_5)

    //#endregion

    //#region Setup assets

    // Initialize
    const reflectionProbe1 = prefabs['reflection probe'].instantiate(map)
    prefabs.darkness.instantiate(map)

    // Intro
    const introScene = prefabs.introscene.instantiate(map)

    // Ambient
    introScene.destroyObject(TIMES._1_AMBIENT)
    const ambientScene = prefabs.ambientscene.instantiate(map, TIMES._1_AMBIENT)
    const ambientFlare = prefabs.ambientflare.instantiate(map, TIMES._1_AMBIENT)

    // Buildup
    ambientScene.destroyObject(TIMES._3_BUILDUP)

    const flower = prefabs.flower.instantiate(map, TIMES._3_BUILDUP)
    const explosions = prefabs.explosions.instantiate(map, TIMES._3_BUILDUP)
    const buildupPanel = prefabs.builduppanel.instantiate(map, TIMES._3_BUILDUP)

    flower.destroyObject(102)

    const buildupParticles = prefabs.buildupparticles.instantiate(map, 104.5)
    const buildupSphere = prefabs.buildupsphere.instantiate(map, 104.5)
    const veinBacklight = prefabs.veinbacklight.instantiate(map, 108.5)

    // Drop
    rm.destroyObjects(map, [
        explosions,
        buildupPanel,
        buildupParticles,
        buildupSphere,
        veinBacklight,
        reflectionProbe1,
    ], 111.25)

    const dropScene = prefabs.dropscene.instantiate(map, TIMES._4_DROP)

    // Outro
    const reflectionProbe2 = prefabs['reflection probe'].instantiate(map, TIMES._5_OUTRO)
    dropScene.destroyObject(TIMES._5_OUTRO)

    const endingScene = prefabs.endingscene.instantiate(map, TIMES._5_OUTRO)

    // Outro Text
    rm.destroyObjects(map, [
        endingScene,
        ambientFlare,
        reflectionProbe2,
    ], TIMES._6_TEXT)

    const outroText = prefabs.outrotext.instantiate(map, TIMES._6_TEXT)

    //#endregion

    //#region Asset control

    const glassNoteMaterials = [materials.glassnote, materials.glassarrow, materials.glassnote_debris]
    const reflectiveNoteMaterials = [materials.reflectivenote, materials.reflectivenote_debris]
    const dropNoteMaterials = [materials.dropnote, materials.dropnote_debris]

    rm.assignObjectPrefab(map, {
        saber: {
            type: 'Both',
            asset: prefabs.saberbase.path,
            trailAsset: materials.sabertrail.path,
            trailDuration: 0.4,
            trailTopPos: [0, 0, 1],
            trailBottomPos: [0, 0, 0],
            // trailGranularity: 100,
            trailSamplingFrequency: 100,
        },
    })

    // Intro

    glassNoteMaterials.forEach((x) =>
        x.set(map, {
            _FadeDistance: 10,
        })
    )

    const introFilter = (e: rm.BasicEvent) => e.type === 1
    const introEvents = map.lightEvents.filter((x) => introFilter(x))
    map.lightEvents = map.lightEvents.filter((x) => !introFilter(x))

    materials.introskybox.set(
        map,
        {
            _Zoom: 0,
            _ID: 0,
            _Light: 0,
            _Hue: 1,
            _RingCompress: 0,
        },
        0,
        34 - 19,
        'easeOutCirc',
    )

    for (let i = 0; i < introEvents.length - 1; i++) {
        const e = introEvents[i]
        const e2 = introEvents[i + 1]
        const dur = e2.beat - e.beat

        materials.introskybox.set(
            map,
            {
                _Zoom: [[0, 0], [1, 1]],
                _ID: i,
            },
            e.beat,
            dur,
        )
    }

    materials.introskybox.set(
        map,
        {
            _Hue: [[1, 0], [0, 1]],
        },
        1,
        20 - 1,
    )

    materials.introskybox.set(
        map,
        {
            _Opacity: [[1, 0], [0, 1, 'easeInExpo']],
            _RingCompress: [[0, 0], [1, 1, 'easeInQuint']],
        },
        TIMES._1_AMBIENT - 3,
        3,
    )

    materials.introskybox.set(
        map,
        {
            _Light: [[0, 0], [1, 1]],
        },
        19,
        TIMES._1_AMBIENT - 19,
        'easeOutCirc',
    )

    reflectiveNoteMaterials.forEach((x) => {
        x.set(
            map,
            {
                _FadeDistance: [[40, 0], [100, 1]],
            },
            0,
            20,
            'easeInCirc',
        )
    })

    // Ambient
    glassNoteMaterials.forEach((x) => {
        x.set(
            map,
            {
                _FadeDistance: [[10, 0], [30, 1, 'easeOutCirc']],
            },
            TIMES._1_AMBIENT,
            0.2,
        )
    })

    rm.animateTrack(map, {
        beat: TIMES._1_AMBIENT,
        duration: 10,
        track: ambientScene.id,
        animation: {
            scale: [
                [0.1, 1, 1, 0],
                [1, 1, 1, 1, 'easeOutExpo'],
            ],
        },
    })

    materials.ambientskybox.set(
        map,
        {
            _Opacity: [[0, 0], [1, 1]],
        },
        TIMES._1_AMBIENT,
        1,
        'easeOutExpo',
    )

    materials.ambientflare.set(
        map,
        {
            _FlareOpacity: [[0, 0], [1, 0.06], [0, 1, 'easeInSine']],
        },
        TIMES._1_AMBIENT,
        4,
    )

    materials.ambientskybox.set(
        map,
        {
            _LightBrightness: [[0, 0], [1, 0.06], [0, 1, 'easeInSine']],
        },
        TIMES._1_AMBIENT,
        4,
    )

    function getFlicker(brightness: number, alt: boolean): rm.ComplexPointsLinear {
        return alt ? [[brightness * 1.2, 0.05, 'easeInExpo'], [brightness, 0.4]] : [[brightness, 0.07, 'easeInBounce']]
    }

    for (let i = 38; i < TIMES._3_BUILDUP; i += 4) {
        const alt = i % 8 === 6

        materials.ambientflare.set(
            map,
            {
                _FlareOpacity: [[0, 0], ...getFlicker(1, alt), [0, 1, 'easeInSine']],
            },
            i - 0.15,
            4,
        )

        materials.ambientskybox.set(
            map,
            {
                _LightBrightness: [[0, 0], ...getFlicker(1, alt), [0, 1, 'easeInSine']],
            },
            i - 0.15,
            4,
        )
    }

    materials.ambientskybox.set(
        map,
        {
            _Evolve: [[0, 0], [1, 1, 'easeOutSine']],
        },
        65.5,
        TIMES._3_BUILDUP - 65.5,
    )

    materials.implosion.set(map, {
        _Distance: 1,
    })
    materials.ribbon.set(map, {
        _Opacity: 0,
    })

    materials.ribbon.set(
        map,
        {
            _Opacity: [[0, 0], [1, 0.98], [0, 1, 'easeInExpo']],
            _Movement: [[1, 0], [0, 1, 'easeOutSine']],
            // _DissolveBorder: [[1, 0], [0, 0.98, 'easeStep']], not sure what this is for?
        },
        68.5,
        TIMES._3_BUILDUP - 68.5,
    )

    materials.ambientskybox.set(
        map,
        {
            _Opacity: [[1, 0], [0, 1, 'easeInExpo']],
        },
        95,
        TIMES._3_BUILDUP - 95,
    )

    materials.implosion.set(
        map,
        {
            _Distance: [[1, 0], [0.2, 1, 'easeInExpo']],
        },
        95,
        TIMES._3_BUILDUP - 95,
    )

    materials.ambientparticles.set(
        map,
        {
            _Opacity: [[1, 0], [0, 1, 'easeInExpo']],
        },
        97,
        TIMES._3_BUILDUP - 97,
    )

    // Buildup
    materials.buildupeffects.blit(map, TIMES._3_BUILDUP, 104.5 - TIMES._3_BUILDUP)
    materials.buildupeffects.blit(map, 108.5, 111.25 - 108.5)

    glassNoteMaterials.forEach((x) =>
        x.set(map, {
            _Cutout: 1,
        })
    )

    materials.ambientparticles.set(
        map,
        {
            _Opacity: [[1, 0], [0, 1, 'easeInExpo']],
        },
        97,
        TIMES._3_BUILDUP - 97,
    )

    materials.ambientflare.set(
        map,
        {
            _Opacity: [[1, 0], [0, 0.5, 'easeInExpo'], [1, 1, 'easeOutExpo']],
            _Exaggerate: [[0, 0], [1, 0.5], [0, 0.5]],
            _FlareBrightness: [[-10, 0], [0.18, 0.5, 'easeStep']],
            _FlareOpacity: [1],
            _Size: [[1.2, 0], [0.72, 0.5, 'easeStep']],
            _LightBrightness: 0,
        },
        TIMES._3_BUILDUP - 2 * 0.5,
        2,
    )

    materials.ambientflare.set(
        map,
        {
            _Exaggerate: [[0, 0], [1, 1, 'easeOutExpo']],
        },
        TIMES._3_BUILDUP,
        104 - TIMES._3_BUILDUP,
    )

    materials.pedal.set(
        map,
        {
            _LightBrightness: [[60, 0], [569.5, 0.25, 'easeOutCirc'], [30, 1]],
            _PetalCurl: [[0.35, 0], [0, 0.5, 'easeOutBack']],
        },
        TIMES._3_BUILDUP,
        104 - TIMES._3_BUILDUP,
    )

    materials.flowertiddle.set(
        map,
        {
            _Brightness: [[0, 0.1], [1, 0.5], [0, 1]],
            _Glow: [[0, 0.1], [1, 0.5], [0, 1]],
        },
        TIMES._3_BUILDUP,
        101 - TIMES._3_BUILDUP,
    )

    materials.explosion.set(
        map,
        {
            _Distance: [[0, 0], [0.6, 1, 'easeOutExpo']],
            _Opacity: [[0.2, 0], [0, 0.8, 'easeOutExpo']],
        },
        TIMES._3_BUILDUP,
        102 - TIMES._3_BUILDUP,
    )

    materials.ambientflare.set(
        map,
        {
            _Flutter: [[0.05, 0], [-0.6, 1]],
        },
        99,
        101 - 99,
    )

    materials.ambientflare.set(
        map,
        {
            _Opacity: [[1, 0], [0, 1]],
        },
        99,
        103 - 99,
    )

    materials.builduppanel.set(
        map,
        {
            _Opacity: [[0, 0.15], [1, 0.8], [0, 1]],
        },
        TIMES._3_BUILDUP,
        105 - TIMES._3_BUILDUP,
    )

    materials.builduppanel.set(
        map,
        {
            _Progress: [[0, 0], [35, 1, 'easeOutCubic']],
            _Angle: [[0, 0], [200.4, 1, 'easeOutExpo']],
        },
        98.4,
        105 - 99,
    )

    materials.shaft.set(
        map,
        {
            _Progress: [[0, 0], [1, 1]],
        },
        104.5,
        108.5 - 104.5,
    )

    materials.outline.set(
        map,
        {
            _Progress: [[0, 0], [1, 1]],
        },
        104.5,
        108.5 - 104.5,
    )

    rm.animateTrack(map, {
        track: buildupSphere.id,
        beat: 104.5,
        duration: 108.5 - 104.5,
        animation: {
            position: [[0, 0, 700, 0], [0, 0, 800, 1, 'easeInOutSine']],
            rotation: [[0, 0, 30, 0], [0, 0, 0, 1, 'easeOutExpo']],
        },
    })

    materials.veinbacklight.set(
        map,
        {
            _Progress: [[0, 0], [1, 1]],
        },
        108.5,
        111.25 - 108.5,
    )

    materials.ambientflare.set(
        map,
        {
            _CenterBrightness: -16,
            _Flutter: 0,
            _Exaggerate: [[0, 0.2], [0.2, 1]],
            _Opacity: [[0, 0.4], [1, 1]],
        },
        108.5,
        111.25 - 108.5,
    )

    materials.ambientflare.set(
        map,
        {
            _Opacity: 0,
        },
        111.25,
    )

    materials.buildupwisps.set(
        map,
        {
            _Opacity: [[0, 0], [1, 1, 'easeInQuart']],
        },
        108.5,
        111.25 - 108.5,
    )

    materials.buildupwisps.set(
        map,
        {
            _Opacity: 0,
        },
        111.25,
    )

    // Drop
    let DROP_STEP = 1.75

    let offset = 0
    const offsetStep = 1.2

    materials.ambientflare.set(
        map,
        {
            _Opacity: 0,
            _Steepness: 40,
            _Size: 1.25,
            _FlareBrightness: 0.1,
            _CenterBrightness: 1,
            _Flutter: 0,
        },
        TIMES._4_DROP,
    )

    dropNoteMaterials.forEach((x) => {
        rm.setMaterialProperty(map, {
            asset: x.path,
            properties: [{
                id: 'VOID',
                type: 'Keyword',
                value: true,
            }],
        })
        x.set(
            map,
            {
                _Cutout: 0,
            },
        )
    })
    rm.setMaterialProperty(map, {
        asset: materials.dropnotearrow.path,
        properties: [{
            id: 'FLICKER',
            type: 'Keyword',
            value: true,
        }],
    })

    dropNoteMaterials.forEach((x) =>
        rm.setMaterialProperty(map, {
            beat: TIMES._4_DROP,
            asset: x.path,
            properties: [{
                id: 'VOID',
                type: 'Keyword',
                value: false,
            }],
        })
    )
    rm.setMaterialProperty(map, {
        beat: TIMES._4_DROP,
        asset: materials.dropnotearrow.path,
        properties: [{
            id: 'FLICKER',
            type: 'Keyword',
            value: false,
        }],
    })

    // horizontal blur
    materials.dropeffects.blit(map, {
        beat: TIMES._4_DROP,
        duration: DROP_DUR,
        priority: 0,
        pass: 0,
    })
    // vertical blur
    materials.dropeffects.blit(map, {
        beat: TIMES._4_DROP,
        duration: DROP_DUR,
        priority: 1,
        pass: 1,
    })

    let mirrorIndex = 0
    const mirrors = [5, 3, 7, 4]

    for (let i = TIMES._4_DROP; i < TIMES._5_OUTRO; i += DROP_STEP) {
        if (i >= 138.5) DROP_STEP += 0.25

        const rand = mulberry32(i)

        // Skybox
        const mirror = mirrors[mirrorIndex % mirrors.length]
        mirrorIndex++

        materials.dropskybox.set(
            map,
            {
                _TimeOffset: [
                    [offset, 0],
                    [offset + offsetStep / 2, 0.5, 'easeOutExpo'],
                    [offset + offsetStep, 1, 'easeInExpo'],
                ],
                _Flicker: [[100, 0], [0.589, 0.4, 'easeOutQuart']],
                _Opacity: [[1.3, 0], [1, 0.2], [0, 1]],
                _Mirrors: mirror,
                _HueShift: [[0, 0], [1, 1]],
            },
            i,
            DROP_STEP,
        )

        rm.animateTrack(map, {
            track: dropScene.id,
            beat: i,
            duration: DROP_STEP,
            animation: {
                scale: [
                    [1, 1, 0.8, 0],
                    [1, 1, 1, 1, 'easeOutExpo'],
                ],
                position: [
                    [0, 0, 0, 0],
                    [0, 0, 50, 1],
                ],
                rotation: [0, 0, rand(0, 360)],
            },
        })

        // Veins
        const flip = mirrorIndex % 2 === 0 ? 1 : -1

        materials.dropveins.set(
            map,
            {
                _Flicker: [[0.2, 0], [0, 1, 'easeOutExpo']],
                _Opacity: [[1, 0], [0, 1, 'easeInCirc']],
                _VeinSwirl: [rand(0, 1) * flip],
            },
            i,
            DROP_STEP,
        )

        // Wisps
        materials.dropwisps.set(
            map,
            {
                _Opacity: [[0.2, 0], [1, 0.9, 'easeInCirc'], [0, 1]],
            },
            i,
            DROP_STEP,
        )

        // Flare
        materials.ambientflare.set(
            map,
            {
                _Exaggerate: [[0.1, 0], [1, 0.8], [0.1, 1, 'easeInCirc']],
                _Opacity: [[0.4, 0], [1, 0.8, 'easeOutExpo'], [
                    0.4,
                    1,
                    'easeInCirc',
                ]],
            },
            i,
            DROP_STEP,
        )

        rm.animateTrack(map, i, ambientFlare.track.value!, 0, {
            rotation: [0, rand(-30, 30), rand(0, 360)],
        })

        // Post Processing
        materials.dropeffects.set(
            map,
            {
                _Strength: [[1, 0], [0, 0.7, 'easeOutQuad'], [
                    -0.3,
                    1,
                    'easeInCirc',
                ]],
                _Blur: [[1, 0], [0, 0.7, 'easeOutExpo'], [
                    -0.3,
                    1,
                    'easeInCirc',
                ]],
            },
            i,
            DROP_STEP,
        )

        offset += offsetStep
    }

    // Outro
    materials.ambientflare.set(map, {
        _LightBrightness: materials.ambientflare.defaults._LightBrightness,
    }, TIMES._5_OUTRO)

    rm.animateTrack(map, {
        track: endingScene.id,
        beat: TIMES._5_OUTRO,
        duration: 18,
        animation: {
            position: [
                [0, 0, -10, 0],
                [0, 0, 0, 1, 'easeOutExpo'],
            ],
            scale: [
                [1, 1, 1.6, 0],
                [1, 1, 1, 0.7, 'easeOutExpo'],
            ],
        },
        easing: 'easeOutCirc',
    })

    rm.animateTrack(map, TIMES._5_OUTRO, ambientFlare.track.value!, 0, {
        rotation: [0, 0, 0],
    })

    materials.ambientflare.set(
        map,
        {
            _Steepness: 1,
            _Size: 1.21,
            _FlareBrightness: 0.76,
            _CenterBrightness: [[1, 0], [13.63, 1]],
            _Flutter: 0.03,
            _Exaggerate: [[1, 0], [0, 0.5, 'easeOutExpo']],
            _Opacity: [[0.4, 0], [0.1, 1, 'easeOutExpo']],
        },
        TIMES._5_OUTRO,
        12,
    )

    materials.ambientparticles.set(
        map,
        {
            _Opacity: 1,
        },
        TIMES._4_DROP,
    )

    {
        const high = 1.76
        for (let i = 144.75; i <= TIMES._6_TEXT; i += 4) {
            const arr: rm.ComplexPointsLinear = i % 8 === 4.75
                ? [[high, 0.1, 'easeOutExpo']]
                : [[high, 0, 'easeOutExpo'], [high * 0.6, 0.01, 'easeStep'], [
                    high,
                    0.02,
                    'easeStep',
                ]]

            materials.ambientflare.set(
                map,
                {
                    _FlareBrightness: [[0, 0], ...arr, [0, 1]],
                },
                i - 0.1,
                4,
            )
        }
    }

    {
        const high = 0.4

        materials.endingskybox.set(
            map,
            {
                _Flash: [[2, 0], [0, 1, 'easeOutExpo']],
            },
            TIMES._5_OUTRO,
            1,
        )

        for (let i = 148.75; i <= TIMES._6_TEXT; i += 8) {
            const arr: rm.ComplexPointsLinear = i !== 164.75
                ? [[high, 0.1, 'easeOutExpo']]
                : [[high, 0, 'easeOutExpo'], [high * 0.9, 0.01, 'easeStep'], [
                    high,
                    0.02,
                    'easeStep',
                ]]

            materials.endingskybox.set(
                map,
                {
                    _Flash: [[0, 0], ...arr, [0, 1]],
                },
                i,
                2,
            )
        }
    }

    materials.endingskybox.set(
        map,
        {
            _Darken: [[1, 0], [0, 1, 'easeInCirc']],
        },
        TIMES._6_TEXT - 1,
        1,
    )

    // Outro text
    const endingOffset = 10000

    materials['pala sdf - outro text'].set(
        map,
        {
            _Whiteness: [[0, 0], [1, 0.8]],
            _Opacity: [[5, 0], [1, 0.2], [0, 1]],
            _PlaneOffset: endingOffset,
        },
        TIMES._6_TEXT,
        8,
    )

    materials['pala sdf - outro text'].set(
        map,
        {
            _Opacity: 0,
        },
        TIMES._6_TEXT + 8,
    )

    rm.animateTrack(map, {
        track: outroText.id,
        beat: TIMES._6_TEXT,
        duration: 5,
        animation: {
            position: [[0, 0, endingOffset, 0], [
                0,
                0,
                0.5 + endingOffset,
                1,
                'easeOutSine',
            ]],
        },
    })

    rm.animateTrack(map, {
        track: headTrack,
        beat: TIMES._6_TEXT,
        animation: {
            position: [0, 0, endingOffset],
        },
    })

    rm.assignPlayerToTrack(map, {
        track: 'rightHand',
        target: 'RightHand',
    })

    rm.animateTrack(map, {
        beat: TIMES._6_TEXT,
        track: 'rightHand',
        animation: {
            position: [0, -69420, 0],
        },
    })

    //#endregion

    //#region Settings Setup

    rm.setCameraProperty(map, {
        properties: {
            depthTextureMode: ['Depth'],
        },
    })

    map.difficultyInfo.requirements = [
        'Chroma',
        'Noodle Extensions',
        'Vivify',
    ]

    map.difficultyInfo.settingsSetter = {
        graphics: {
            bloomGraphicsSettings: 'On',
            maxShockwaveParticles: 0,
            screenDisplacementEffectsEnabled: true,
        },
        chroma: {
            disableEnvironmentEnhancements: false,
        },
        modifiers: {
            noFailOn0Energy: true,
        },
        playerOptions: {
            leftHanded: false,
            reduceDebris: false,
        },
        colors: {},
        environments: {},
    }

    rm.setRenderingSettings(map, {
        qualitySettings: {
            realtimeReflectionProbes: rm.BOOLEAN.True,
        },
        renderSettings: {
            fog: rm.BOOLEAN.False,
        },
    })

    //#endregion
}

//#region Export

await Promise.all([
    doMap('HardStandard'),
    doMap('NormalStandard')
])

info.environmentName = 'BillieEnvironment'

pipeline.export({
    outputDirectory: '../OutputMaps/you',
    zip: {
        name: 'you',
        includeBundles: true,
    },
})

//#endregion