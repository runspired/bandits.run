import { Request } from '@warp-drive/ember';
import { withReactiveResponse } from '@warp-drive/core/request';

const query = withReactiveResponse<unknown>({
  url: '/api/organization.json',
});

<template>
  <Request @query={{query}}>
    <:content>Loaded</:content>
  </Request>
</template>
