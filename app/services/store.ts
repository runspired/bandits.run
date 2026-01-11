import { AddressObjectSchema, LocationSchema } from '#app/data/location.ts';
import { MonthSchema } from '#app/data/month.ts';
import { OrganizationSchema } from '#app/data/organization.ts';
import { RealizedEventDateSchema } from '#app/data/realized-event-date.ts';
import { RecurrenceObjectSchema, RunOptionObjectSchema, TrailRunSchema } from '#app/data/run.ts';
import { ScheduleDaySchema } from '#app/data/schedule.ts';
import { UserSchema } from '#app/data/user.ts';
import { WeekSchema } from '#app/data/week.ts';
import { useRecommendedStore } from '@warp-drive/core';
import { JSONAPICache } from '@warp-drive/json-api';

const Store = useRecommendedStore({
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
});

type Store = InstanceType<typeof Store>;

export default Store;
