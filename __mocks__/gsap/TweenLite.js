module.exports = {
  TweenLite: class {
    constructor() {
      this.to = jest.fn().mockReturnThis();
      this.fromTo = jest.fn().mockReturnThis();
    }
  }
};
