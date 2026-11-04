/**
 * PRD M03 FR-03.3 / X3: tarif hanya boleh berasal dari matriks zona.
 * Klien tidak boleh menentukan ongkir sendiri.
 */
export const ZONE_1 = 'Zona 1' as const;
export const ZONE_2 = 'Zona 2' as const;

export type CampusZone = typeof ZONE_1 | typeof ZONE_2;

export const ZONE_FARE_MATRIX: Record<CampusZone, Record<CampusZone, number>> = {
  [ZONE_1]: {
    [ZONE_1]: 4_000,
    [ZONE_2]: 6_000,
  },
  [ZONE_2]: {
    [ZONE_1]: 6_000,
    [ZONE_2]: 5_000,
  },
};

export function normalizeZone(value: unknown): CampusZone {
  if (value === 1 || value === '1') return ZONE_1;
  if (value === 2 || value === '2') return ZONE_2;
  if (typeof value !== 'string') {
    throw new Error(`Zona tidak dikenal: ${String(value)}`);
  }

  const normalized = value.trim().toLowerCase().replace(/[_-]+/g, ' ');
  if (['zona 1', 'zone 1', 'dalam kampus', 'area dalam kampus'].includes(normalized)) {
    return ZONE_1;
  }
  if (['zona 2', 'zone 2', 'luar kampus', 'area luar', 'gerbang'].includes(normalized)) {
    return ZONE_2;
  }
  throw new Error(`Zona tidak dikenal: ${value}`);
}

/**
 * Matriks ongkir kampus:
 * - sesama Zona 1 = Rp 4.000
 * - Zona 1 <-> Zona 2 = Rp 6.000
 * - sesama Zona 2 = Rp 5.000
 */
export function calculateDeliveryFee(fromZone: unknown, toZone: unknown): number {
  const from = normalizeZone(fromZone);
  const to = normalizeZone(toZone);
  return ZONE_FARE_MATRIX[from][to];
}
