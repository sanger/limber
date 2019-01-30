export default {
  comment: {
    attributes: {
      title: 'Comment Title',
      description: 'This is a comment'
    }
  },
  commentWithUser: {
    resource: 'comment',
    attributes: {},
  },
  custom_user: {
    resource: 'user',
    attributes: {
      login: 'js',
      first_name: 'Jane',
      last_name: 'Smith'
    }
  }
}
