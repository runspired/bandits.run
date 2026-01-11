import { withDefaults } from "@warp-drive/core/reactive";
import type { Type } from "@warp-drive/core/types/symbols";

export interface User {
  id: string;
  $type: 'user';
  firstName: string | null;
  lastName: string | null;
  email: string | null;
  phoneNumber: string | null;
  hasWhatsApp: boolean;
  stravaId: string | null;
  instagramHandle: string | null;
  descriptionHtml: string | null;
  [Type]: 'user';
}

export const UserSchema = withDefaults({
  type: 'user',
  fields: [
    { name: 'firstName', kind: 'field' },
    { name: 'lastName', kind: 'field' },
    { name: 'email', kind: 'field' },
    { name: 'phoneNumber', kind: 'field' },
    { name: 'hasWhatsApp', kind: 'field' },
    { name: 'stravaId', kind: 'field' },
    { name: 'instagramHandle', kind: 'field' },
    { name: 'descriptionHtml', kind: 'field' },
  ]
});
