import { withDefaults as withLegacyDefaults } from "@warp-drive/legacy/model/migration-support";
import { withDefaults } from "@warp-drive/core/reactive";
import type { PolarisResourceSchema } from "@warp-drive/core/types/schema/fields";

type LegacySchema = Parameters<typeof withLegacyDefaults>[0];

export function withLegacy(schema: LegacySchema) {
  const schema2 = withDefaults(schema as PolarisResourceSchema);
  return withLegacyDefaults(schema2 as LegacySchema);
}
