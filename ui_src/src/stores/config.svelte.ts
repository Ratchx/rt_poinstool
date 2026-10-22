import { fmt } from '../lib/format'
import type { BlipRule, Bootstrap, Keys, MarkerRule, RadiusRule } from '../lib/types'
import { blipRuleOf, keysOf, markerRuleOf, radiusOf } from '../lib/wire'

const LOCALE: Record<string, string> = {
  title: 'Points Tool',
  points: '%s จุด',
  add: 'เพิ่มจุด',
  list: 'รายการ',
  export: 'ส่งออก',
  close: 'ปิด',
  hide: 'ซ่อนวง',
  show: 'แสดงวง',
  empty: 'ยังไม่มีจุด',
  empty_hint: 'กด %s ตรงที่ยืนอยู่เพื่อมาร์คจุดแรก',
  unnamed: 'ไม่มีชื่อ',
  default_radius: 'รัศมีเริ่มต้น %s m',

  edit: 'แก้ไขจุด %s',
  pick: 'เลือกจุดจากรายการเพื่อแก้ไข',
  name: 'ชื่อ',
  name_hint: 'ไม่บังคับ ใช้ตอนส่งออก',
  radius: 'รัศมี',
  position: 'ตำแหน่ง',
  heading: 'หันหน้า',
  here: 'ย้ายมาตรงที่ยืน',
  teleport: 'วาร์ปไปจุดนี้',
  remove: 'ลบจุด',
  remove_confirm: 'กดอีกครั้งเพื่อลบ',
  copy: 'คัดลอก',
  ground: 'ติดพื้น',

  marker: 'Marker',
  marker_link: 'X = Y',
  marker_fit: 'เท่ารัศมี',
  tint: 'สี',
  alpha: 'A',

  prop: 'Prop',
  prop_hint: 'ชื่อโมเดล เช่น prop_atm_01',
  map: 'แผนที่',
  blip: 'Blip',
  area: 'วงรัศมีบนแผนที่',
  sprite: 'ไอคอน',
  color: 'สี',
  scale: 'ขนาด',

  format: 'รูปแบบ',
  with_radius: 'ใส่รัศมี',
  with_label: 'ใส่ชื่อ',
  with_model: 'ใส่โมเดล',
  with_marker: 'ใส่ marker',
  with_blip: 'ใส่ blip',
  copy_all: 'คัดลอกทั้งหมด',
  clear: 'ล้างทั้งหมด',
  clear_confirm: 'กดอีกครั้งเพื่อล้าง',

  added: 'เพิ่มจุด %s แล้ว',
  copied: 'คัดลอก %s แล้ว',
  copied_all: 'คัดลอก %s จุดแล้ว',
  full: 'มาร์คได้สูงสุด %s จุด',
  moved: 'ย้ายจุด %s มาตรงนี้แล้ว',
  removed: 'ลบจุด %s แล้ว',
  cleared: 'ล้างจุดทั้งหมดแล้ว',
  prop_set: 'วาง %s ที่จุด %s แล้ว',
  prop_removed: 'เอา prop ออกจากจุด %s แล้ว',
  prop_invalid: 'ไม่พบโมเดล prop ชื่อ %s',
  grounded: 'วางจุด %s ติดพื้นแล้ว',
  ground_failed: 'หาพื้นใต้จุดไม่เจอ ลองเข้าไปใกล้จุดก่อน',
  failed: 'ทำรายการไม่สำเร็จ',
}

class ConfigStore {
  scale = $state(1)
  locale = $state<Record<string, string>>({ ...LOCALE })
  keys = $state<Keys>({ add: 'J', menu: 'F7' })
  precision = $state(2)
  radius = $state<RadiusRule>({ default: 2, min: 0.1, max: 100, step: 0.1 })
  limit = $state(300)
  labelLength = $state(32)
  modelLength = $state(64)
  marker = $state<MarkerRule>({ sizeMin: 0.05, sizeMax: 100 })
  blip = $state<BlipRule>({ spriteMax: 2000, colorMax: 255, scaleMin: 0.1, scaleMax: 5 })

  t(key: string, ...args: (string | number)[]): string {
    return fmt(this.locale[key] ?? key, ...args)
  }

  setKeys(value: Partial<Keys> | undefined) {
    this.keys = keysOf(value, this.keys)
  }

  apply(payload: Bootstrap) {
    if (typeof payload.scale === 'number') this.scale = payload.scale
    if (payload.locale && typeof payload.locale === 'object' && !Array.isArray(payload.locale)) this.locale = { ...this.locale, ...payload.locale }
    if (typeof payload.precision === 'number') this.precision = Math.max(0, Math.min(6, Math.round(payload.precision)))
    if (typeof payload.limit === 'number') this.limit = payload.limit
    if (typeof payload.labelLength === 'number') this.labelLength = payload.labelLength
    if (typeof payload.modelLength === 'number') this.modelLength = payload.modelLength

    this.radius = radiusOf(payload.radius, this.radius)
    this.blip = blipRuleOf(payload.blip, this.blip)
    this.marker = markerRuleOf(payload.marker, this.marker)
    this.setKeys(payload.keys)
  }
}

export const config = new ConfigStore()
