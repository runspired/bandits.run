import { AddressObjectSchema, LocationSchema } from '#app/data/location.ts';
import { MonthSchema } from '#app/data/month.ts';
import { OrganizationSchema } from '#app/data/organization.ts';
import { RealizedEventDateSchema } from '#app/data/realized-event-date.ts';
import { getNextOccurrence, RecurrenceObjectSchema, RunOptionObjectSchema, TrailRunSchema } from '#app/data/run.ts';
import { ScheduleDaySchema } from '#app/data/schedule.ts';
import { UserSchema } from '#app/data/user.ts';
import { WeekSchema } from '#app/data/week.ts';
import { useLegacyStore } from '@warp-drive/legacy';
import { JSONAPICache } from '@warp-drive/json-api';

const Store = useLegacyStore({
  linksMode: true,
  legacyRequests: false,
  cache: JSONAPICache,
  handlers: [
    // -- your handlers here
  ],
  schemas: [
    ScheduleDaySchema,
    LocationSchema,
    AddressObjectSchema,
    UserSchema,
    RunOptionObjectSchema,
    RecurrenceObjectSchema,
    OrganizationSchema,
    TrailRunSchema,
    RealizedEventDateSchema,
    MonthSchema,
    WeekSchema
  ],
  derivations: [
    getNextOccurrence
  ]
});

type Store = InstanceType<typeof Store>;

export default Store;
