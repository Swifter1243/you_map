import * as rm from 'file:E:/Users/Programs/ReMapper Vivify/src/mod.ts'
import * as assetinfo from "./assetinfo.json" with { type: "json" }

type AssetPath<T extends string> = `${string}.${T}`
type PrefabPath = AssetPath<'prefab'>
type MaterialPath = AssetPath<'mat'>

type PrefabMap = Record<string, PrefabPath>

type MaterialProperties = Record<string, rm.MATERIAL_PROP_TYPE>
type MaterialMap = Record<string, {
    path: MaterialPath
    properties: MaterialProperties
}>

type MaterialPropertyMap = {
    static: {
        'Texture': rm.FILEPATH
        'Float': number
        'Color': rm.ColorType
    }
    animated: {
        'Texture': rm.FILEPATH
        'Float': rm.ComplexKeyframesLinear | string
        'Color': rm.ComplexKeyframesColor | string
    }
}

class Prefab {
    path: PrefabPath

    constructor(path: PrefabPath) {
        this.path = path
    }
}

class Material<T extends MaterialProperties = MaterialProperties> {
    path: MaterialPath
    properties: T

    constructor(path: MaterialPath, properties: T) {
        this.path = path
        this.properties = properties
    }

    set<K extends keyof T>(
        prop: K,
        value: MaterialPropertyMap['static'][T[K]],
        time = 0,
        callback?: (event: rm.CustomEventInternals.SetMaterialProperty) => void,
    ) {
        // LMFAO
        const fixedValue =
            (typeof value === 'number'
                ? [value]
                : (typeof value === 'object' && Array.isArray(value) &&
                        typeof value[0] === 'number' && value.length === 3
                    ? [...value, 0]
                    : value)) as rm.MaterialPropertyValue

        const e = new rm.CustomEvent(time).setMaterialProperty(this.path, [
            {
                id: prop as string,
                type: this.properties[prop],
                value: fixedValue,
            },
        ])
        if (callback) callback(e)
        e.push(false)
    }

    animate<K extends keyof T>(
        prop: K,
        value: MaterialPropertyMap['animated'][T[K]],
        time = 0,
        duration = 0,
        easing?: rm.EASE,
        callback?: (event: rm.CustomEventInternals.SetMaterialProperty) => void,
    ) {
        const e = new rm.CustomEvent(time).setMaterialProperty(this.path, [
            {
                id: prop as string,
                type: this.properties[prop],
                value: value,
            },
        ])
        e.duration = duration
        if (easing) e.easing = easing
        if (callback) callback(e)
        e.push(false)
    }
}

function makePrefabMap<T extends PrefabMap>(map: T) {
    const newMap: Record<string, Prefab> = {}

    Object.entries(map).forEach(([k, v]) => {
        newMap[k] = new Prefab(v)
    })

    return newMap as Record<keyof T, Prefab>
}

function makeMaterialMap<T extends MaterialMap>(map: T) {
    const newMap: Record<string, Material> = {}

    Object.entries(map).forEach(([k, v]) => {
        newMap[k] = new Material<typeof v.properties>(v.path, v.properties)
    })

    return newMap as Record<keyof T, Material<T[keyof T]['properties']>>
}

const mats = makeMaterialMap({
    DropNote: {
        path: 'assets/materials/dropnote.mat',
        properties: {
            _Offset: 'Float',
        },
    },
})

mats.DropNote.set('_Offset', 0, 0)
mats.DropNote.animate('_Offset', [[0, 0]], 0, 0)