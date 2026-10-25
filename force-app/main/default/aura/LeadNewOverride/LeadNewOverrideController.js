({
    init: function (component) {
        component.find('flow').startFlow('Lead_New_Enquiry');
    },
    statusChange: function (component, event) {
        if (event.getParam('status') !== 'FINISHED' && event.getParam('status') !== 'FINISHED_SCREEN') return;
        var lead = null, highProfile = false;
        (event.getParam('outputVariables') || []).forEach(function (v) {
            if (v.name === 'var_Lead') lead = v.value;
            if (v.name === 'isHighProfile') highProfile = v.value;
        });
        var nav = component.find('nav');
        if (lead && lead.Id && !highProfile) {
            nav.navigate({ type: 'standard__recordPage', attributes: { recordId: lead.Id, objectApiName: 'Lead', actionName: 'view' } });
        } else {
            nav.navigate({ type: 'standard__objectPage', attributes: { objectApiName: 'Lead', actionName: 'list' }, state: { filterName: 'Recent' } });
        }
    }
})
