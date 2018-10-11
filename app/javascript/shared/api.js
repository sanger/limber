/* Generates a Sequencescape API object
 * Needs to be initialized with the root URL
 * Usage example:
 *
 * import ApiModule from 'shared/api'
 * const Api = ApiModule(baseUrl: 'http://sequencescape.url/port')
 * var plate = Api.Plate.find('1')
 */

const {
  JSORMBase,
  attr,
  belongsTo,
  hasMany
  // etc
} = require('jsorm/dist/jsorm')

const Api = function (options) {
  const ApplicationRecord = JSORMBase.extend({
    static: {
      baseUrl: options.baseUrl || 'http://localhost:3000',
      apiNamespace: options.apiNamespace || '/api/v1'
    }
  })
  return {
    Event: ApplicationRecord.extend({
      static: {
        jsonapiType: 'events'
      },
      attrs: {
        occuredAt: attr(),
        userIdentifier: attr(),
        limsId: attr(),
        eventType: belongsTo(),
        roles: hasMany(),
        subjects: hasMany()
      },
      methods: {}
    }),

    EventType: ApplicationRecord.extend({
      static: {
        jsonapiType: 'event_types'
      },
      attrs: {
        key: attr(),
        description: attr(),
        events: hasMany()
      },
      methods: {}
    }),

    Role: ApplicationRecord.extend({
      static: {
        jsonapiType: 'roles'
      },
      attrs: {
        roleType: belongsTo(),
        event: belongsTo(),
        subject: belongsTo()
      },
      methods: {}
    }),

    RoleType: ApplicationRecord.extend({
      static: {
        jsonapiType: 'role_types'
      },
      attrs: {
        key: attr(),
        description: attr(),
        roles: hasMany()
      },
      methods: {}
    }),

    Subject: ApplicationRecord.extend({
      static: {
        jsonapiType: 'subjects'
      },
      attrs: {
        friendlyName: attr(),
        uuid: attr(),
        subjectType: belongsTo(),
        roles: hasMany(),
        events: hasMany()
      },
      methods: {}
    }),

    SubjectType: ApplicationRecord.extend({
      static: {
        jsonapiType: 'subject_types'
      },
      attrs: {
        key: attr(),
        description: attr(),
        subjects: hasMany()
      },
      methods: {}
    })
  }
}

export default Api
