import * as rm from 'file:E:/Users/Programs/ReMapper Vivify/src/mod.ts'
import * as assetinfo from './assetinfo.json' with { type: 'json' }

type PrefabMap = Record<string, string>

type MaterialProperties = Record<string, rm.MATERIAL_PROP_TYPE>

type MaterialMap = Record<string, {
    path: string
    properties: Record<string, Partial<Record<rm.MATERIAL_PROP_TYPE, unknown>>>
}>

type FixedMaterialMap<BaseMaterial extends MaterialMap[string]> = {
    path: string
    properties: {
        [MaterialProperty in keyof BaseMaterial['properties']]:
            BaseMaterial['properties'][MaterialProperty] extends
                Record<string, unknown> ? Extract<
                    keyof BaseMaterial['properties'][MaterialProperty],
                    rm.MATERIAL_PROP_TYPE
                >
                : never
    }
}

type RawKeyframesLinear = rm.AbstractRawKeyframeArray<[number]>

type MaterialPropertyMap = {
    static: {
        'Texture': rm.FILEPATH
        'Float': number
        'Color': rm.ColorType
        'Vector': rm.Vec4
    }
    animated: {
        'Texture': rm.FILEPATH
        'Float': RawKeyframesLinear | string
        'Color': rm.RawKeyframesColor | string
        'Vector': rm.RawKeyframesVec4 | string
    }
}

class Prefab {
    path: string
    name: string
    private iteration = 0;

    constructor(path: string, name: string) {
        this.path = path
        this.name = name
    }

    instantiate(time = 0) {
        const id = `${this.name}_${this.iteration}`
        new rm.CustomEvent(time).instantiatePrefab(this.path, id, id).push()
        this.iteration++
        return new PrefabInstance(id)
    }
}

class PrefabInstance {
    id: string

    constructor(id: string) {
        this.id = id
    }

    destroy(time = 0) {
        new rm.CustomEvent(time).destroyPrefab(this.id).push()
    }
}

class Material<T extends MaterialProperties = MaterialProperties> {
    path: string
    name: string
    properties: T

    constructor(path: string, name: string, properties: T) {
        this.path = path
        this.name = name
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
        newMap[k] = new Prefab(v, k)
    })

    return newMap as Record<keyof T, Prefab>
}

function fixMaterial<T extends MaterialMap['properties']>(map: T) {
    const newMap = {
        path: map.path,
        properties: {},
    } as FixedMaterialMap<T>

    Object.entries(map.properties).forEach(([prop, type]) => {
        ;(newMap.properties as unknown as Record<string, unknown>)[prop] =
            Object.keys(type)[0] as rm.MATERIAL_PROP_TYPE
    })

    return newMap
}

function makeMaterialMap<T extends MaterialMap>(map: T) {
    const newMap: Record<string, Material> = {}

    Object.entries(map).forEach(([k, v]) => {
        type props = FixedMaterialMap<typeof v>['properties']
        const fixed = fixMaterial(v)
        newMap[k] = new Material<props>(v.path, k, fixed.properties)
    })

    type Output = {
        [V in keyof T]: Material<FixedMaterialMap<T[V]>['properties']>
    }

    return newMap as Output
}

export const mats = makeMaterialMap(assetinfo.default.materials)
export const prefabs = makePrefabMap(assetinfo.default.prefabs)
