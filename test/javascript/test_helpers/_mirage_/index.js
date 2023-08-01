/*
  Mock server for testing purposes
  see: https://miragejs.com
  Usage (assuming jest):
    import { startMirage } from '../_mirage_'
    let mirageServer;

    beforeEach(() => {
      mirageServer = startMirage();
    });

    afterEach(() => {
      mirageServer.shutdown();
    });
*/
import { Server } from 'miragejs'

export function startMirage() {
  return new Server({
    environment: 'test',

    routes() {
      this.post('asset_groups/:id/print', (schema, request) => {
        return '{ "success": true, "message": "Printed" }'
      })
    },
  })
}
