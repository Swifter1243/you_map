import * as rm from 'file:E:/Users/Programs/ReMapper Vivify/src/mod.ts'
import * as bundleinfo from './bundleinfo.json' with { type: 'json' }

const map = await rm.readDifficultyV3('ExpertPlusNoArrows', 'HardStandard')

// ----------- { SCRIPT } -----------

/*
This script was created on ReMapper V3, and later ported to V4.
I realized that having an example for launch would be ideal.
*/

const bundle = rm.loadBundle(bundleinfo)
const materials = bundle.materials
const prefabs = bundle.prefabs

const TIMES = {
    // forcing sorting order in intellisense
    a_INTRO: 0,
    b_AMBIENT: 34,
    c_AMBIENT_RISE: 70,
    d_BUILDUP: 98,
    e_DROP: 112.5,
    f_OUTRO: 140.75,
    g_TEXT: 172.75,
} as const // this provides the value in the type instead of "number"

//#region Environment

// Clear space
rm.getBaseEnvironment((x) => {
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
rm.assignTrackParent(0, ['noteChild'], 'player').push()
rm.assignPlayerToTrack(0, 'player').push()

// Intro notes
rm.assignObjectPrefab({
    colorNotes: {
        track: 'introNote',
        asset: prefabs.reflectivenote.path,
        debrisAsset: prefabs.reflectivenote_debris.path,
    },
}).push()

map.allNotes.forEach((x) => {
    if (
        x.beat >= 0 && x.beat <= 33 && x instanceof rm.ColorNote
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
rm.assignObjectPrefab({
    colorNotes: {
        track: 'ambientNote',
        asset: prefabs.glassnote.path,
        debrisAsset: prefabs.glassnote_debris.path,
    },
}).push()

rm.assignPathAnimation({
    track: 'ambientNote',
    animation: {
        offsetPosition: [
            [0, 0, 700, 0],
            [0, 0, 0, 0.455, 'easeOutCirc'],
        ],
    },
}).push()

rm.assignPathAnimation({
    beat: 34,
    duration: 4,
    track: 'ambientNote',
    animation: {
        offsetPosition: [0, 0, 0],
    },
    easing: 'easeInOutExpo',
}).push()

map.allNotes.forEach((x) => {
    if (
        x.beat >= 33 && x.beat <= 98.5 &&
        x instanceof rm.ColorNote
    ) {
        x.disableNoteGravity = true
        x.noteJumpOffset = 4
        x.track.add('ambientNote')

        const rand = mulberry32(x.beat * 10)

        let scalar = Math.sin(x.beat * 0.3) * 0.5 + 0.5

        const movement = (x.beat - TIMES.c_AMBIENT_RISE) /
            (TIMES.d_BUILDUP - TIMES.c_AMBIENT_RISE)

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

rm.assignPlayerToTrack({
    track: 'head',
    target: 'Head',
}).push()

{
    const headStartMovingBeat = TIMES.c_AMBIENT_RISE

    rm.animateTrack({
        track: 'head',
        beat: headStartMovingBeat,
        duration: TIMES.d_BUILDUP - headStartMovingBeat,
        animation: {
            position: [
                [0, 0, 0, 0],
                [0, 0.8, -4, 0.86, 'easeInOutQuart'],
                [0, 0, 0, 1, 'easeInOutQuart'],
            ],
        },
    }).push()
}

// Drop
const DROP_DUR = TIMES.f_OUTRO - TIMES.e_DROP

rm.assignObjectPrefab({
    colorNotes: {
        track: 'dropNote',
        asset: prefabs.dropnote.path,
        debrisAsset: prefabs.dropnote_debris.path,
    },
}).push()

rm.assignPathAnimation({
    beat: TIMES.b_AMBIENT - 1,
    track: 'dropNote',
    duration: 2,
    animation: {
        dissolve: [[1, 0], [0, 0.1]],
    },
    easing: 'easeInOutCirc',
}).push()

rm.assignPathAnimation({
    track: 'dropHitNote',
    animation: {
        scale: [0, 0, 0],
    },
}).push()

rm.assignPathAnimation({
    track: 'dropHitNote',
    beat: 107,
    duration: TIMES.e_DROP - 107,
    easing: 'easeInOutExpo',
    animation: {
        scale: [1, 1, 1],
    },
}).push()

rm.assignPathAnimation({
    track: 'dropHitNote',
    beat: 111.25,
    animation: {
        scale: [0, 0, 0],
    },
}).push()

rm.assignPathAnimation({
    track: 'dropHitNote',
    beat: TIMES.e_DROP,
    animation: {
        scale: [1, 1, 1],
    },
}).push()

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
        x.beat >= TIMES.e_DROP && x.beat <= TIMES.f_OUTRO &&
        x instanceof rm.ColorNote
    ) {
        x.track.add('dropNote')
        x.noteJumpOffset = 1.5
        x.noteJumpSpeed = 15

        if (x.beat > TIMES.e_DROP + 1) {
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

function doDropNoteMods(note: rm.ColorNote, index: number) {
    note.track.add('dropHitNote')
    note.noteJumpOffset = 5

    const rand = mulberry32(note.beat + 6942)

    const track1 = 'dropPath1_' + index
    const track2 = 'dropPath2_' + index
    note.track.add([track1, track2])

    // initialization
    rm.assignPathAnimation({
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
    }).push()

    let lastDir = -1
    for (let t = TIMES.e_DROP; t <= note.beat && t < TIMES.f_OUTRO - 0.5; t += 1.75) {
        const nextNote = map.colorNotes.find(
            (n) => (n.beat >= t && n.cutDirection != lastDir),
        )!
        lastDir = nextNote.cutDirection
        const nextDir = cutDirectionAngle(nextNote.cutDirection)
        const scalar = rand(10, 15)
        const deltaX = Math.cos(rm.toRadians(nextDir)) * scalar
        const deltaY = Math.sin(rm.toRadians(nextDir)) * scalar

        rm.assignPathAnimation({
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
        }).push()

        const randRange = 30
        const randRot = () => rand(-randRange, randRange)
        rm.assignPathAnimation({
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
        }).push()
    }
}

// Outro
rm.assignObjectPrefab({
    colorNotes: {
        track: 'outroNote',
        asset: prefabs.glassnote.path,
        debrisAsset: prefabs.glassnote_debris.path,
    },
}).push()

map.allNotes.forEach((x) => {
    if (x.beat >= 141 && x instanceof rm.ColorNote) {
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
    rm.assignObjectPrefab({
        loadMode: 'Additive',
        colorNotes: {
            track,
            asset: prefab.path,
        },
    }).push()
}

insertTrailerCamera(TIMES.a_INTRO + 14, prefabs.trailercamera_1)
insertTrailerCamera(TIMES.b_AMBIENT + 18, prefabs.trailercamera_2)
insertTrailerCamera(TIMES.c_AMBIENT_RISE + 20, prefabs.trailercamera_3)
insertTrailerCamera(TIMES.e_DROP + 10, prefabs.trailercamera_4)
insertTrailerCamera(TIMES.f_OUTRO + 10, prefabs.trailercamera_5)

//#endregion

//#region Setup assets

// Initialize
prefabs.darkness.instantiate()

// Intro
const introScene = prefabs.introscene.instantiate()

// Ambient
introScene.destroy(TIMES.b_AMBIENT)
const ambientScene = prefabs.ambientscene.instantiate(TIMES.b_AMBIENT)
const ambientFlare = prefabs.ambientflare.instantiate(TIMES.b_AMBIENT)

// Buildup
ambientScene.destroy(TIMES.d_BUILDUP)

const flower = prefabs.flower.instantiate(TIMES.d_BUILDUP)
const explosions = prefabs.explosions.instantiate(TIMES.d_BUILDUP)
const buildupPanel = prefabs.builduppanel.instantiate(TIMES.d_BUILDUP)

flower.destroy(102)

const buildupParticles = prefabs.buildupparticles.instantiate(104.5)
const buildupSphere = prefabs.buildupsphere.instantiate(104.5)
const veinBacklight = prefabs.veinbacklight.instantiate(108.5)

// Drop
rm.destroyPrefabInstances([
    explosions,
    buildupPanel,
    buildupParticles,
    buildupSphere,
    veinBacklight,
], 111.25)

const dropScene = prefabs.dropscene.instantiate(TIMES.e_DROP)

// Outro
dropScene.destroy(TIMES.f_OUTRO)

const endingScene = prefabs.endingscene.instantiate(TIMES.f_OUTRO)

// Outro Text
rm.destroyPrefabInstances([
    endingScene,
    ambientFlare,
], TIMES.g_TEXT)

const outroText = prefabs.outrotext.instantiate(TIMES.g_TEXT)

//#endregion

//#region Asset control

const glassNoteMaterials = [materials.glassnote, materials.glassarrow, materials.glassnote_debris]
const reflectiveNoteMaterials = [materials.reflectivenote, materials.reflectivenote_debris]
const dropNoteMaterials = [materials.dropnote, materials.dropnote_debris]

rm.assignObjectPrefab({
    saber: {
        type: 'Both',
        asset: prefabs.saberbase.path,
        trailAsset: materials.sabertrail.path,
        trailDuration: 0.4,
        trailTopPos: [0, 0, 1],
        trailBottomPos: [0, 0, 0],
        // trailGranularity: 100,
        trailSamplingFrequency: 100
    },
}).push()

// Intro

glassNoteMaterials.forEach((x) => x.set('_FadeDistance', 10))

const introFilter = (e: rm.BasicEvent) => e.type === 1
const introEvents = map.lightEvents.filter((x) => introFilter(x))
map.lightEvents = map.lightEvents.filter((x) => !introFilter(x))

materials.introskybox.set(
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
        {
            _Zoom: [[0, 0], [1, 1]],
            _ID: i,
        },
        e.beat,
        dur,
    )
}

materials.introskybox.set('_Hue', [[1, 0], [0, 1]], 1, 20 - 1)

materials.introskybox.set(
    {
        _Opacity: [[1, 0], [0, 1, 'easeInExpo']],
        _RingCompress: [[0, 0], [1, 1, 'easeInQuint']],
    },
    TIMES.b_AMBIENT - 3,
    3,
)

materials.introskybox.set(
    '_Light',
    [[0, 0], [1, 1]],
    19,
    TIMES.b_AMBIENT - 19,
    'easeOutCirc',
)

reflectiveNoteMaterials.forEach((x) => {
    x.set(
        '_FadeDistance',
        [[40, 0], [100, 1]],
        0,
        20,
        'easeInCirc',
    )
})

// Ambient
glassNoteMaterials.forEach((x) => {
    x.set(
        '_FadeDistance',
        [[10, 0], [30, 1, 'easeOutCirc']],
        TIMES.b_AMBIENT,
        0.2,
    )
})

rm.animateTrack({
    beat: TIMES.b_AMBIENT,
    duration: 10,
    track: ambientScene.id,
    animation: {
        scale: [
            [0.1, 1, 1, 0],
            [1, 1, 1, 1, 'easeOutExpo'],
        ],
    },
}).push()

materials.ambientskybox.set(
    '_Opacity',
    [[0, 0], [1, 1]],
    TIMES.b_AMBIENT,
    1,
    'easeOutExpo',
)

materials.ambientflare.set(
    '_FlareOpacity',
    [[0, 0], [1, 0.06], [0, 1, 'easeInSine']],
    TIMES.b_AMBIENT,
    4,
)

materials.ambientskybox.set(
    '_LightBrightness',
    [[0, 0], [1, 0.06], [0, 1, 'easeInSine']],
    TIMES.b_AMBIENT,
    4,
)

function getFlicker(brightness: number, alt: boolean): rm.ComplexKeyframesLinear {
    return alt
        ? [[brightness * 1.2, 0.05, 'easeInExpo'], [brightness, 0.4]]
        : [[brightness, 0.07, 'easeInBounce']]
}

for (let i = 38; i < TIMES.d_BUILDUP; i += 4) {
    const alt = i % 8 === 6

    materials.ambientflare.set(
        '_FlareOpacity',
        [[0, 0], ...getFlicker(1, alt), [0, 1, 'easeInSine']],
        i - 0.15,
        4,
    )

    materials.ambientskybox.set(
        '_LightBrightness',
        [[0, 0], ...getFlicker(1, alt), [0, 1, 'easeInSine']],
        i - 0.15,
        4,
    )
}

materials.ambientskybox.set(
    '_Evolve',
    [[0, 0], [1, 1, 'easeOutSine']],
    65.5,
    TIMES.d_BUILDUP - 65.5,
)

materials.implosion.set('_Distance', 1)
materials.ribbon.set('_Opacity', 0)

materials.ribbon.set(
    {
        _Opacity: [[0, 0], [1, 0.98], [0, 1, 'easeInExpo']],
        _Movement: [[1, 0], [0, 1, 'easeOutSine']],
        _DissolveBorder: [[1, 0], [0, 0.98, 'easeStep']],
    },
    68.5,
    TIMES.d_BUILDUP - 68.5,
)

materials.ambientskybox.set(
    '_Opacity',
    [[1, 0], [0, 1, 'easeInExpo']],
    95,
    TIMES.d_BUILDUP - 95,
)

materials.implosion.set(
    '_Distance',
    [[1, 0], [0.2, 1, 'easeInExpo']],
    95,
    TIMES.d_BUILDUP - 95,
)

materials.ambientparticles.set(
    '_Opacity',
    [[1, 0], [0, 1, 'easeInExpo']],
    97,
    TIMES.d_BUILDUP - 97,
)

// Buildup
materials.buildupeffects.blit(TIMES.d_BUILDUP, 104.5 - TIMES.d_BUILDUP)
materials.buildupeffects.blit(108.5, 111.25 - 108.5)

glassNoteMaterials.forEach((x) => x.set('_Cutout', 1))

materials.ambientparticles.set(
    '_Opacity',
    [[1, 0], [0, 1, 'easeInExpo']],
    97,
    TIMES.d_BUILDUP - 97,
)

materials.ambientflare.set(
    {
        '_Opacity': [[1, 0], [0, 0.5, 'easeInExpo'], [1, 1, 'easeOutExpo']],
        '_Exaggerate': [[0, 0], [1, 0.5], [0, 0.5]],
        '_FlareBrightness': [[-10, 0], [0.18, 0.5, 'easeStep']],
        '_FlareOpacity': 1,
        '_Size': [[1.2, 0], [0.72, 0.5, 'easeStep']],
        '_LightBrightness': 0,
    },
    TIMES.d_BUILDUP - 2 * 0.5,
    2,
)

materials.ambientflare.set(
    '_Exaggerate',
    [[0, 0], [1, 1, 'easeOutExpo']],
    TIMES.d_BUILDUP,
    104 - TIMES.d_BUILDUP,
)

materials.pedal.set(
    {
        '_LightBrightness': [[60, 0], [569.5, 0.25, 'easeOutCirc'], [30, 1]],
        '_PetalCurl': [[0.35, 0], [0, 0.5, 'easeOutBack']],
    },
    TIMES.d_BUILDUP,
    104 - TIMES.d_BUILDUP,
)

materials.flowertiddle.set(
    {
        '_Brightness': [[0, 0.1], [1, 0.5], [0, 1]],
        '_Glow': [[0, 0.1], [1, 0.5], [0, 1]],
    },
    TIMES.d_BUILDUP,
    101 - TIMES.d_BUILDUP,
)

materials.explosion.set(
    {
        _Distance: [[0, 0], [0.6, 1, 'easeOutExpo']],
        _Opacity: [[0.2, 0], [0, 0.8, 'easeOutExpo']],
    },
    TIMES.d_BUILDUP,
    102 - TIMES.d_BUILDUP,
)

materials.ambientflare.set(
    '_Flutter',
    [[0.05, 0], [-0.6, 1]],
    99,
    101 - 99,
)

materials.ambientflare.set(
    '_Opacity',
    [[1, 0], [0, 1]],
    99,
    103 - 99,
)

materials.builduppanel.set(
    '_Opacity',
    [[0, 0.15], [1, 0.8], [0, 1]],
    TIMES.d_BUILDUP,
    105 - TIMES.d_BUILDUP,
)

materials.builduppanel.set(
    {
        '_Progress': [[0, 0], [35, 1, 'easeOutCubic']],
        '_Angle': [[0, 0], [200.4, 1, 'easeOutExpo']],
    },
    98.4,
    105 - 99,
)

materials.shaft.set(
    '_Progress',
    [[0, 0], [1, 1]],
    104.5,
    108.5 - 104.5,
)

materials.outline.set(
    '_Progress',
    [[0, 0], [1, 1]],
    104.5,
    108.5 - 104.5,
)

rm.animateTrack({
    track: buildupSphere.id,
    beat: 104.5,
    duration: 108.5 - 104.5,
    animation: {
        position: [[0, 0, 700, 0], [0, 0, 800, 1, 'easeInOutSine']],
        rotation: [[0, 0, 30, 0], [0, 0, 0, 1, 'easeOutExpo']],
    },
}).push()

materials.veinbacklight.set(
    '_Progress',
    [[0, 0], [1, 1]],
    108.5,
    111.25 - 108.5,
)

materials.ambientflare.set(
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
    '_Opacity',
    0,
    111.25,
)

materials.buildupwisps.set(
    '_Opacity',
    [[0, 0], [1, 1, 'easeInQuart']],
    108.5,
    111.25 - 108.5,
)

materials.buildupwisps.set(
    '_Opacity',
    0,
    111.25,
)

// Drop
let DROP_STEP = 1.75

let offset = 0
const offsetStep = 1.2

materials.ambientflare.set(
    {
        _Opacity: 0,
        _Steepness: 40,
        _Size: 1.25,
        _FlareBrightness: 0.1,
        _CenterBrightness: 1,
        _Flutter: 0,
    },
    TIMES.e_DROP,
)

dropNoteMaterials.forEach((x) => {
    x.set(
        {
            _Void: 1,
            _Cutout: 0,
        },
    )
})

materials.dropnotearrow.set('_Flicker', 1)
dropNoteMaterials.forEach((x) => x.set('_Void', 0, TIMES.e_DROP))
materials.dropnotearrow.set('_Flicker', 0, TIMES.e_DROP)

materials.dropeffects.blit(TIMES.e_DROP, DROP_DUR)

let mirrorIndex = 0
const mirrors = [5, 3, 7, 4]

for (let i = TIMES.e_DROP; i < TIMES.f_OUTRO; i += DROP_STEP) {
    if (i >= 138.5) DROP_STEP += 0.25

    const rand = mulberry32(i)

    // Skybox
    const mirror = mirrors[mirrorIndex % mirrors.length]
    mirrorIndex++

    materials.dropskybox.set(
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

    rm.animateTrack({
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
    }).push()

    // Veins
    const flip = mirrorIndex % 2 === 0 ? 1 : -1

    materials.dropveins.set(
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
        {
            _Opacity: [[0.2, 0], [1, 0.9, 'easeInCirc'], [0, 1]],
        },
        i,
        DROP_STEP,
    )

    // Flare
    materials.ambientflare.set(
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

    rm.animateTrack(i, ambientFlare.id, 0, {
        rotation: [0, rand(-30, 30), rand(0, 360)],
    }).push()

    // Post Processing
    materials.dropeffects.set(
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
materials.ambientflare.set('_LightBrightness', materials.ambientflare.defaults._LightBrightness, TIMES.f_OUTRO)

rm.animateTrack({
    track: endingScene.id,
    beat: TIMES.f_OUTRO,
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
}).push()

rm.animateTrack(TIMES.f_OUTRO, ambientFlare.id, 0, {
    rotation: [0, 0, 0],
}).push()

materials.ambientflare.set(
    {
        _Steepness: 1,
        _Size: 1.21,
        _FlareBrightness: 0.76,
        _CenterBrightness: [[1, 0], [13.63, 1]],
        _Flutter: 0.03,
        _Exaggerate: [[1, 0], [0, 0.5, 'easeOutExpo']],
        _Opacity: [[0.4, 0], [0.1, 1, 'easeOutExpo']],
    },
    TIMES.f_OUTRO,
    12,
)

materials.ambientparticles.set(
    '_Opacity',
    1,
    TIMES.e_DROP,
)

{
    const high = 1.76
    for (let i = 144.75; i <= TIMES.g_TEXT; i += 4) {
        const arr: rm.ComplexKeyframesLinear = i % 8 === 4.75
            ? [[high, 0.1, 'easeOutExpo']]
            : [[high, 0, 'easeOutExpo'], [high * 0.6, 0.01, 'easeStep'], [
                high,
                0.02,
                'easeStep',
            ]]

        materials.ambientflare.set(
            '_FlareBrightness',
            [[0, 0], ...arr, [0, 1]],
            i - 0.1,
            4,
        )
    }
}

{
    const high = 0.4

    materials.endingskybox.set(
        '_Flash',
        [[2, 0], [0, 1, 'easeOutExpo']],
        TIMES.f_OUTRO,
        1,
    )

    for (let i = 148.75; i <= TIMES.g_TEXT; i += 8) {
        const arr: rm.ComplexKeyframesLinear = i !== 164.75
            ? [[high, 0.1, 'easeOutExpo']]
            : [[high, 0, 'easeOutExpo'], [high * 0.9, 0.01, 'easeStep'], [
                high,
                0.02,
                'easeStep',
            ]]

        materials.endingskybox.set(
            '_Flash',
            [[0, 0], ...arr, [0, 1]],
            i,
            2,
        )
    }
}

materials.endingskybox.set(
    '_Darken',
    [[1, 0], [0, 1, 'easeInCirc']],
    TIMES.g_TEXT - 1,
    1,
)

// Outro text
const endingOffset = 10000

materials.outrotext.set(
    {
        _Whiteness: [[0, 0], [1, 0.8]],
        _Opacity: [[5, 0], [1, 0.2], [0, 1]],
        _PlaneOffset: endingOffset,
    },
    TIMES.g_TEXT,
    8,
)

materials.outrotext.set(
    '_Opacity',
    0,
    TIMES.g_TEXT + 8,
)

rm.animateTrack({
    track: outroText.id,
    beat: TIMES.g_TEXT,
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
}).push()

rm.animateTrack({
    track: 'head',
    beat: TIMES.g_TEXT,
    animation: {
        position: [0, 0, endingOffset],
    },
}).push()

rm.assignPlayerToTrack({
    track: 'rightHand',
    target: 'RightHand',
}).push()

rm.animateTrack({
    beat: TIMES.g_TEXT,
    track: 'rightHand',
    animation: {
        position: [0, -69420, 0],
    },
}).push()

//#endregion

// ----------- { OUTPUT } -----------

rm.setCameraProperty({
    depthTextureMode: ['Depth'],
}).push()

map.require('Chroma')
map.require('Noodle Extensions')
map.require('Vivify')

rm.getActiveInfo()._environmentName = 'BillieEnvironment'
map.rawSettings = rm.SETTINGS_PRESET.CHROMA_SETTINGS
map.settings.bloom = true
map.settings.maxShockwaveParticles = 0
map.settings.reduceDebris = false

rm.setRenderingSetting({
    qualitySettings: {
        realtimeReflectionProbes: true
    }
}).push()

map.save()

rm.exportZip(['ExpertPlusNoArrows'], undefined, bundleinfo)
