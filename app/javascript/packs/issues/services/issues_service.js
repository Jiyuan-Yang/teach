import axios from 'axios'

export default class IssuesService {
  constructor({issuesEndpoint}) {
    this.issuesEndpoint = issuesEndpoint;
  }

  all(filterParams = {}) {
    return axios.get(this.issuesEndpoint, {
      params: filterParams
    });
  }

  newIssue(issue) {
    return axios.post(this.issuesEndpoint, {
      issue: issue
    });
  }
}