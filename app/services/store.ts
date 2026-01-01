import { ScheduleDaySchema } from '#app/data/schedule.ts';
import { useRecommendedStore } from '@warp-drive/core';
import { JSONAPICache } from '@warp-drive/json-api';

const Store = useRecommendedStore({
  cache: JSONAPICache,
  handlers: [
    // -- your handlers here
  ],
  schemas: [
    ScheduleDaySchema
  ],
});

type Store = InstanceType<typeof Store>;

export default Store;
