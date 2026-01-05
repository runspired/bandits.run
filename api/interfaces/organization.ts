export interface Organization {
  name: string;
  contacts: string[];
  website: string | null;
  stravaId: string | null;
  stravaHandle: string | null;
  meetupId: string | null;
  instagramHandle: string | null;
  email: string | null;
  phoneNumber: string | null;
}

export interface JSONAPIOrganization {
  type: 'organization';
  id: string;
  attributes: {
    name: string;
    website: string | null;
    stravaId: string | null;
    stravaHandle: string | null;
    meetupId: string | null;
    instagramHandle: string | null;
    email: string | null;
    phoneNumber: string | null;
    descriptionHtml: string | null;
  },
  relationships: {
    runs: {
      meta: { count: number },
      links: { related: string },
      data?: { type: 'run', id: string }[]
    },
    contacts: {
      data: { type: 'user', id: string }[]
    }
  }
}
