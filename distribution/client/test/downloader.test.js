'use strict';

const Downloader = require('../src/lib/downloader');
const mkdirp     = require('mkdirp');

describe('the Downloader class', () => {
  describe('download()', () => {
    let dir  = '/tmp/jest';

    beforeEach(() => {
      mkdirp.sync(dir);
    });

    it('should return promise', () => {
      let response = Downloader.download('https://jenkins.io/index.html', dir);
      expect(Promise.resolve(response)).toBe(response);
    });

    it('should fail on url without final basename-ish path', () => {
      expect(() => {
        Promise.resolve(Downloader.download('https://jenkins.io/', dir));
      }
      ).toThrow();
    });
  });
});