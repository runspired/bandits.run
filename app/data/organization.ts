import { withDefaults } from "@warp-drive/legacy/model/migration-support";
import type { AsyncHasMany } from "@warp-drive/legacy/model";
import type { User } from "./user";
import type { Type } from "@warp-drive/core/types/symbols";
import type { TrailRun } from "./run";

export interface Organization {
  id: string;
  $type: 'organization';
  name: string;
  website: string | null;
  stravaId: string | null;
  stravaHandle: string | null;
  meetupId: string | null;
  instagramHandle: string | null;
  email: string | null;
  phoneNumber: string | null;
  descriptionHtml: string | null;
  runs: AsyncHasMany<TrailRun>;
  contacts: User[];
  [Type]: 'organization';
}

export const OrganizationSchema = withDefaults({
  type: 'organization',
  fields: [
    { name: 'name', kind: 'field' },
    { name: 'website', kind: 'field' },
    { name: 'stravaId', kind: 'field' },
    { name: 'stravaHandle', kind: 'field' },
    { name: 'meetupId', kind: 'field' },
    { name: 'instagramHandle', kind: 'field' },
    { name: 'email', kind: 'field' },
    { name: 'phoneNumber', kind: 'field' },
    { name: 'descriptionHtml', kind: 'field' },
    { name: 'runs',
      kind: 'hasMany',
      type: 'trail-run',
      options: { linksMode: true, async: false, inverse: 'owner'  }
    },
    { name: 'contacts',
      kind: 'hasMany',
      type: 'user',
      options: { linksMode: true, async: false, inverse: null  }
    },
  ]
});
