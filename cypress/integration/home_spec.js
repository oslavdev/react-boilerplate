describe('Home page', () => {
    it('Visits the home page', () => {
      cy.visit('https://app.xu.local')

      cy.contains("Home");
    })
})