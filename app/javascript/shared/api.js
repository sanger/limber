/*
 * Autogenerated by sequencescape on 2018-10-22 15:31:19 +0100"
 * bundle exec rake jsorm:create_config"
 *
 * Generates a Sequencescape API object
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
      // We need to extend fetchOptions as JSORM is using the
      // wrong accept header
      fetchOptions() {
        var opts = JSORMBase.fetchOptions()
        opts.headers.Accept = 'application/vnd.api+json'
        return opts
      }
    }
  })

  return {
    Purpose: ApplicationRecord.extend({
      static: { jsonapiType: 'purposes' },
      attrs: {
        id: attr(),
        uuid: attr(),
        name: attr(),
      },
      methods: {}
    }),
    Request: ApplicationRecord.extend({
      static: { jsonapiType: 'requests' },
      attrs: {
        id: attr(),
        uuid: attr(),
        role: attr(),
        state: attr(),
        priority: attr(),
        options: attr(),
        submission: belongsTo(),
        order: belongsTo(),
        requestType: belongsTo(),
        primerPanel: belongsTo(),
        preCapturePool: belongsTo(),
      },
      methods: {}
    }),
    PreCapturePool: ApplicationRecord.extend({
      static: { jsonapiType: 'pre_capture_pools' },
      attrs: {
        id: attr(),
        uuid: attr(),
      },
      methods: {}
    }),
    Submission: ApplicationRecord.extend({
      static: { jsonapiType: 'submissions' },
      attrs: {
        id: attr(),
        uuid: attr(),
      },
      methods: {}
    }),
    Asset: ApplicationRecord.extend({
      static: { jsonapiType: 'assets' },
      attrs: {
        id: attr(),
        uuid: attr(),
        comments: hasMany()
      },
      methods: {}
    }),
    Well: ApplicationRecord.extend({
      static: { jsonapiType: 'wells' },
      attrs: {
        id: attr(),
        uuid: attr(),
        name: attr(),
        position: attr(),
        state: attr(),
        samples: hasMany(),
        studies: hasMany(),
        projects: hasMany(),
        qcResults: hasMany(),
        requestsAsSource: hasMany(),
        requestsAsTarget: hasMany(),
        aliquots: hasMany(),
        downstreamAssets: hasMany(),
      },
      methods: {}
    }),
    Receptacle: ApplicationRecord.extend({
      static: { jsonapiType: 'receptacles' },
      attrs: {
        id: attr(),
        uuid: attr(),
        name: attr(),
        samples: hasMany(),
        studies: hasMany(),
        projects: hasMany(),
      },
      methods: {}
    }),
    Order: ApplicationRecord.extend({
      static: { jsonapiType: 'orders' },
      attrs: {
        id: attr(),
        uuid: attr(),
      },
      methods: {}
    }),
    Study: ApplicationRecord.extend({
      static: { jsonapiType: 'studies' },
      attrs: {
        id: attr(),
        name: attr(),
        uuid: attr(),
      },
      methods: {}
    }),
    Aliquot: ApplicationRecord.extend({
      static: { jsonapiType: 'aliquots' },
      attrs: {
        id: attr(),
        tagOligo: attr(),
        tagIndex: attr(),
        tag2Oligo: attr(),
        tag2Index: attr(),
        suboptimal: attr(),
        sample: belongsTo(),
        request: belongsTo(),
      },
      methods: {}
    }),
    Plate: ApplicationRecord.extend({
      static: { jsonapiType: 'plates' },
      attrs: {
        id: attr(),
        uuid: attr(),
        name: attr(),
        labwareBarcode: attr(),
        state: attr(),
        numberOfRows: attr(),
        numberOfColumns: attr(),
        createdAt: attr(),
        updatedAt: attr(),
        purpose: belongsTo(),
        samples: hasMany(),
        studies: hasMany(),
        projects: hasMany(),
        wells: hasMany(),
        ancestors: hasMany(),
        descendants: hasMany(),
        parents: hasMany(),
        children: hasMany(),
        comments: hasMany(),
      },
      methods: {}
    }),
    Comment: ApplicationRecord.extend({
      static: { jsonapiType: 'comments' },
      attrs: {
        id: attr(),
        createdAt: attr(),
        updatedAt: attr(),
        description: attr(),
        title: attr(),
        commentable: belongsTo(),
        user: belongsTo(),
      },
      methods: {}
    }),
    User: ApplicationRecord.extend({
      static: { jsonapiType: 'users' },
      attrs: {
        id: attr(),
        uuid: attr(),
        login: attr(),
        firstName: attr(),
        lastName: attr(),
      },
      methods: {}
    }),
    PrimerPanel: ApplicationRecord.extend({
      static: { jsonapiType: 'primer_panels' },
      attrs: {
        id: attr(),
        name: attr(),
        programs: attr(),
      },
      methods: {}
    }),
    Project: ApplicationRecord.extend({
      static: { jsonapiType: 'projects' },
      attrs: {
        id: attr(),
        name: attr(),
        costCode: attr(),
        uuid: attr(),
      },
      methods: {}
    }),
    QcAssay: ApplicationRecord.extend({
      static: { jsonapiType: 'qc_assays' },
      attrs: {
        id: attr(),
        lotNumber: attr(),
        qcResults: attr()
      },
      methods: {}
    }),
    RequestType: ApplicationRecord.extend({
      static: { jsonapiType: 'request_types' },
      attrs: {
        id: attr(),
        uuid: attr(),
        name: attr(),
        key: attr(),
        forMultiplexing: attr(),
      },
      methods: {}
    }),
    Tube: ApplicationRecord.extend({
      static: { jsonapiType: 'tubes' },
      attrs: {
        id: attr(),
        uuid: attr(),
        name: attr(),
        labwareBarcode: attr(),
        state: attr(),
        purpose: belongsTo(),
        samples: hasMany(),
        studies: hasMany(),
        projects: hasMany(),
        comments: hasMany()
      },
      methods: {}
    }),
    Sample: ApplicationRecord.extend({
      static: { jsonapiType: 'samples' },
      attrs: {
        id: attr(),
        name: attr(),
        sangerSampleId: attr(),
        uuid: attr(),
      },
      methods: {}
    }),
    Lane: ApplicationRecord.extend({
      static: { jsonapiType: 'lanes' },
      attrs: {
        id: attr(),
        uuid: attr(),
        name: attr(),
        samples: hasMany(),
        studies: hasMany(),
        projects: hasMany(),
      },
      methods: {}
    }),
    WorkOrder: ApplicationRecord.extend({
      static: { jsonapiType: 'work_orders' },
      attrs: {
        id: attr(),
        orderType: attr(),
        quantity: attr(),
        state: attr(),
        options: attr(),
        atRisk: attr(),
        study: belongsTo(),
        project: belongsTo(),
        sourceReceptacle: belongsTo(),
        samples: hasMany(),
      },
      methods: {}
    }),
  }
}

export default Api
