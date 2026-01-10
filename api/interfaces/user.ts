export interface User {
  firstName: string;
  lastName: string;
  email: string | null;
  phoneNumber: string | null;
  hasWhatsApp: boolean | null;
  stravaId: string | null;
  instagramHandle: string | null;
}

export interface JSONAPIUser {
  type: 'user';
  id: string;
  attributes: {
    firstName: string;
    lastName: string;
    email: string | null;
    phoneNumber: string | null;
    hasWhatsApp: boolean | null;
    stravaId: string | null;
    instagramHandle: string | null;
    descriptionHtml: string | null;
  }
}
